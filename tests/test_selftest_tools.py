import struct
import unittest

from tools.fte4800_selftest import (
    CHIP_ID,
    INFO_BYTES,
    INFO_CHIP_OFFSET,
    READ_REQUEST,
    SPI_READ_WRITE,
    compat_read_request,
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
        self.assertEqual(request[5:9], READ_REQUEST)
        self.assertEqual(request[9:], bytes(INFO_BYTES - 9))

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


if __name__ == "__main__":
    unittest.main()
