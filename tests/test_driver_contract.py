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

    def test_driver_is_a_pure_spi_transport(self):
        # The kernel driver only forwards requests to the real chip; it must
        # never interpret sensor registers or fabricate image data.
        self.assertIn("spi_write_then_read", SOURCE)
        self.assertIn("misc_register", SOURCE)
        self.assertIn('"focal_moh_spi"', SOURCE)

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


if __name__ == "__main__":
    unittest.main()
