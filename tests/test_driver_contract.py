import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "focal_spi.c").read_text()
PROTOCOL = (ROOT / "protocol" / "fte4800_protocol.h").read_text()


class DriverContractTests(unittest.TestCase):
    def test_driver_has_no_synthetic_frame_implementation(self):
        forbidden = (
            "generate_synthetic_frame",
            "fp_sqrt",
            "stage_shifts",
            "full_frame_buf",
            "synthetic frame",
        )
        self.assertFalse(any(token in SOURCE for token in forbidden))

    def test_driver_has_no_system_libfprint_patch_offsets(self):
        forbidden = ("0x66c11", "0x66bdf", "0x70897", "0x88147", "hook_code")
        self.assertFalse(any(token in SOURCE for token in forbidden))

    def test_driver_does_not_put_full_frame_on_kernel_stack(self):
        self.assertNotIn("u8 raw[FTE4800_NATIVE_IMAGE_BYTES]", SOURCE)

    def test_driver_contains_native_ft9368_capture_signature(self):
        self.assertIn("FTE4800_IMAGE_REG", SOURCE)
        self.assertIn("FTE4800_IMAGE_FLAG", SOURCE)
        self.assertIn("spi_sync", SOURCE)
        self.assertIn("FTE4800_NATIVE_IMAGE_BYTES", SOURCE)
        self.assertIn("FTE4800_IMAGE_REG", PROTOCOL)
        self.assertIn("0x90U", PROTOCOL)
        self.assertIn("FTE4800_IMAGE_FLAG", PROTOCOL)
        self.assertIn("0x80U", PROTOCOL)


if __name__ == "__main__":
    unittest.main()
