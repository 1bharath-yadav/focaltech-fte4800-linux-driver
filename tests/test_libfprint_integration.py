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

    def test_patch_stores_fifteen_enrollment_samples(self):
        self.assertIn("#define FTE4800_ENROLL_STAGES     15", PATCH)
        self.assertIn("guint8       *enroll_frames", PATCH)
        self.assertIn('FTE4800_TEMPLATE_MAGIC      "FTE2"', PATCH)
        self.assertIn("sample_count", PATCH)

    def test_patch_uses_ft9368_finger_status(self):
        self.assertIn("fte4800_read_finger_present", PATCH)
        self.assertIn("status[2]", PATCH)
        self.assertIn("FTE4800_FINGER_STATUS_BYTE", PATCH)
        self.assertIn("0xFF, 0x00, 0x00, 0x00", PATCH)

    def test_patch_uses_standard_libfprint_retry_codes(self):
        self.assertIn("FP_DEVICE_RETRY_REMOVE_FINGER", PATCH)
        self.assertIn("FP_DEVICE_RETRY_GENERAL", PATCH)
        self.assertIn("fpi_device_enroll_progress", PATCH)

    def test_patch_has_explicit_press_release_state_gates(self):
        self.assertIn("want_present", PATCH)
        self.assertIn("FTE4800_FINGER_ON_CONFIRM", PATCH)
        self.assertIn("FTE4800_FINGER_OFF_CONFIRM", PATCH)
        self.assertIn("WAIT_DOWN", PATCH)
        self.assertIn("WAIT_UP", PATCH)

    def test_patch_does_not_use_image_signal_for_finger_release(self):
        self.assertNotIn("fte4800_is_finger (tmp", PATCH)
        self.assertIn("image_has_signal", PATCH)


if __name__ == "__main__":
    unittest.main()
