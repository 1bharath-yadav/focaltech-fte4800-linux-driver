import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "focal_spi.c").read_text()
PROTOCOL = (ROOT / "protocol" / "fte4800_protocol.h").read_text()


class DriverContractTests(unittest.TestCase):
    def test_transport_abi_constants_exist(self):
        for token in (
            "FTE4800_COMPAT_READ_ONLY",
            "FTE4800_COMPAT_READ_WRITE",
            "FTE4800_COMPAT_BACK_DATA",
        ):
            self.assertIn(token, PROTOCOL)

    def test_verified_identity_contract_remains_documented(self):
        for token in (
            "FTE4800_INFO_REG",
            "FTE4800_INFO_FLAG",
            "FTE4800_INFO_PAYLOAD_BYTES",
            "FTE4800_INFO_CHIP_OFFSET",
            "FTE4800_CHIP_ID",
        ):
            self.assertIn(token, PROTOCOL)

    def test_transport_does_not_interpret_sensor_commands(self):
        forbidden = (
            "focal_native_xfer",
            "focal_native_read16",
            "focal_native_write16",
            "focal_native_mode_cmd",
            "FTE4800_IMAGE_REG",
            "FTE4800_IMAGE_FLAG",
            "FTE4800_COMPAT_INT_STATUS_ADDR",
            "FTE4800_COMPAT_INT_CLEAR_ADDR",
            "FTE4800_COMPAT_BULK",
            "0x1885",
            "0x00B8",
            "0x00E8",
            "0xC4",
            "0xC8",
            "0xC0",
        )
        self.assertFalse(any(token in SOURCE for token in forbidden))

    def test_no_synthetic_or_library_patch_logic(self):
        forbidden = (
            "generate_synthetic_frame",
            "fp_sqrt",
            "stage_shifts",
            "full_frame_buf",
            "0x66c11",
            "0x66bdf",
            "0x70897",
            "0x88147",
            "hook_code",
        )
        self.assertFalse(any(token in SOURCE for token in forbidden))

    def test_identity_contract_remains_documented(self):
        for token in (
            "FTE4800_INFO_REG",
            "FTE4800_INFO_FLAG",
            "FTE4800_INFO_PAYLOAD_BYTES",
            "FTE4800_INFO_CHIP_OFFSET",
            "FTE4800_CHIP_ID",
        ):
            self.assertIn(token, PROTOCOL)


if __name__ == "__main__":
    unittest.main()
