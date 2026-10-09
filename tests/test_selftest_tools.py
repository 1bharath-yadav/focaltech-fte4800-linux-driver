import struct
import unittest
from pathlib import Path

from tools.fte4800_selftest import (
    CHIP_ID,
    INFO_BYTES,
    INFO_CHIP_OFFSET,
    READ_REQUEST,
    SPI_READ_WRITE,
    WAKE_REQUEST,
    compat_read_request,
    compat_write_request,
    parse_info,
)


class SelftestToolTests(unittest.TestCase):
    def test_compat_request_has_exact_verified_shape(self):
        request = compat_read_request()
        self.assertEqual(len(request), INFO_BYTES)
        self.assertEqual(
            request[:5],
            struct.pack("<BHH", SPI_READ_WRITE, len(READ_REQUEST), INFO_BYTES),
        )
        self.assertEqual(request[5:5 + len(READ_REQUEST)], READ_REQUEST)
        self.assertEqual(request[5 + len(READ_REQUEST):], bytes(INFO_BYTES - 5 - len(READ_REQUEST)))

    def test_vendor_wake_probe_write_uses_exact_compat_abi(self):
        request = compat_write_request(WAKE_REQUEST)
        self.assertEqual(
            request,
            struct.pack("<BHH", SPI_READ_WRITE, 4, 0) + bytes.fromhex("ff 00 00 00"),
        )

    def test_parse_info_uses_verified_chip_offset(self):
        info = bytearray(INFO_BYTES)
        info[INFO_CHIP_OFFSET:INFO_CHIP_OFFSET + 2] = CHIP_ID.to_bytes(2, "big")
        info[0x0F:0x13] = bytes.fromhex("20 22 07 29")
        info[0x17] = 0x40
        info[0x18] = 0x50
        parsed = parse_info(bytes(info))
        self.assertEqual(parsed["chip_id"], CHIP_ID)
        self.assertEqual(parsed["firmware_raw"], "20220729")
        self.assertEqual(parsed["width"], 64)
        self.assertEqual(parsed["height"], 80)

    def test_irq_windows_use_os_poll(self):
        import inspect
        from tools import fte4800_selftest

        source = inspect.getsource(fte4800_selftest.wait_for_irq)
        drain_source = inspect.getsource(fte4800_selftest.drain_irq)
        self.assertIn("select.poll()", source)
        self.assertIn("POLLIN", source)
        self.assertIn("select.poll()", drain_source)
        self.assertIn("POLLIN", drain_source)

    def test_verified_7byte_info_request(self):
        from tools.fte4800_selftest import READ_INFO_REQUEST
        self.assertEqual(
            READ_INFO_REQUEST,
            bytes((0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00)),
        )

    def test_verified_capture_trigger(self):
        from tools.fte4800_capture import CAPTURE_TRIGGER
        self.assertEqual(
            CAPTURE_TRIGGER,
            bytes((0x70, 0x07, 0xF8, 0x00, 0x3B, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00)),
        )

    def test_verified_7byte_image_request(self):
        from tools.fte4800_capture import (
            READ_IMAGE_REQUEST,
            NATIVE_FRAME_BYTES,
            COMPAT_FRAME_BYTES,
        )
        self.assertEqual(
            READ_IMAGE_REQUEST,
            bytes((0x90, 0x80, 0x14, 0x00, 0x00, 0x00, 0x00)),
        )
        self.assertEqual(NATIVE_FRAME_BYTES, 5120)
        self.assertEqual(COMPAT_FRAME_BYTES, 10240)

    def test_unpack_native_frame_to_12bit_adc(self):
        from tools.fte4800_capture import unpack_frame
        mock_raw = bytearray(5120)
        mock_raw[0] = 0x00
        mock_raw[1] = 0xFF
        mock_raw[2] = 0x80
        mock_raw[3] = 0x12

        unpacked = unpack_frame(bytes(mock_raw))
        self.assertEqual(len(unpacked), 10240)
        # Pixel 0: 0x00 -> 0x0000
        self.assertEqual(unpacked[0:2], b"\x00\x00")
        # Pixel 1: 0xFF -> (0xFF << 4) = 0x0FF0 -> b"\x0f\xf0"
        self.assertEqual(unpacked[2:4], b"\x0f\xf0")
        # Pixel 2: 0x80 -> (0x80 << 4) = 0x0800 -> b"\x08\x00"
        self.assertEqual(unpacked[4:6], b"\x08\x00")
        # Pixel 3: 0x12 -> (0x12 << 4) = 0x0120 -> b"\x01\x20"
        self.assertEqual(unpacked[6:8], b"\x01\x20")

    def test_frame_statistics_computes_metrics(self):
        from tools.fte4800_capture import compute_statistics
        data = bytes(range(256)) * 20  # 5120 bytes, range 0..255
        stats = compute_statistics(data)
        self.assertEqual(stats["min"], 0)
        self.assertEqual(stats["max"], 255)
        self.assertEqual(stats["unique"], 256)
        self.assertEqual(stats["nonzero"], 5120 - 20)
        self.assertAlmostEqual(stats["mean"], 127.5, delta=0.5)
        self.assertTrue(stats["has_contrast"])

    def test_save_pgm_format(self):
        import tempfile
        from tools.fte4800_capture import save_pgm
        data = b"\x42" * 5120
        with tempfile.NamedTemporaryFile(suffix=".pgm", delete=False) as tmp:
            tmp_path = tmp.name
        try:
            save_pgm(tmp_path, 64, 80, data)
            content = Path(tmp_path).read_bytes()
            self.assertTrue(content.startswith(b"P5\n64 80\n255\n"))
            self.assertEqual(content[len(b"P5\n64 80\n255\n"):], data)
        finally:
            Path(tmp_path).unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
