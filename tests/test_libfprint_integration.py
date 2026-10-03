import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCH = (ROOT / "libfprint-patches" / "0001-native-fte4800-ft9368-driver.patch").read_text()


class LibfprintIntegrationTests(unittest.TestCase):
    def test_patch_contains_native_capture_trigger(self):
        self.assertIn("0x00, 0x3B", PATCH)
        self.assertIn("60 * 1000", PATCH)
        self.assertIn("0x90, 0x80, 0x14, 0x00", PATCH)

    def test_patch_contains_matcher_source(self):
        self.assertIn("fte4800-match.c", PATCH)
        self.assertIn("fte4800-match.h", PATCH)
        self.assertIn("drivers/fte4800-match.c", PATCH)

    def test_patch_does_not_patch_system_library_offsets(self):
        for token in ("0x66bdf", "0x66c11", "0x88147", "0x88174", "0x148040"):
            self.assertNotIn(token, PATCH)

    def test_patch_stores_multiple_enrollment_samples(self):
        self.assertIn("FTE4800_ENROLL_STAGES", PATCH)
        self.assertIn("enroll_frames", PATCH)
        self.assertIn("FTE1", PATCH)


if __name__ == "__main__":
    unittest.main()
