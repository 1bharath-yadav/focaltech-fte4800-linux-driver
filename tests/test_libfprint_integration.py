import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DRIVER = (ROOT / "libfprint" / "drivers" / "fte4800.c").read_text()
MATCHER = (ROOT / "libfprint" / "drivers" / "fte4800-match.c").read_text()
HEADER = (ROOT / "libfprint" / "drivers" / "fte4800-match.h").read_text()
PATCH = (ROOT / "libfprint-patches" / "0001-native-fte4800-ft9368-driver.patch").read_text()


class LibfprintIntegrationTests(unittest.TestCase):
    def test_canonical_driver_sources_exist(self):
        self.assertIn("FocalTech FTE4800 / FT9368", DRIVER)
        self.assertIn("fte_match", MATCHER)
        self.assertIn("FTE_NANG", HEADER)

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

    def test_stores_fifteen_enrollment_samples(self):
        self.assertIn("#define FTE4800_ENROLL_STAGES         15", DRIVER)
        self.assertIn("guint8       *enroll_frames", DRIVER)
        self.assertIn('FTE4800_TEMPLATE_MAGIC      "FTE2"', DRIVER)
        self.assertIn("sample_count", DRIVER)

    def test_uses_standard_libfprint_retry_codes(self):
        self.assertIn("FP_DEVICE_RETRY_GENERAL", DRIVER)
        self.assertIn("fpi_device_enroll_progress", DRIVER)

    def test_press_release_state_gates_are_explicit(self):
        self.assertIn("fte4800_wait_finger_down", DRIVER)
        self.assertIn("fte4800_wait_finger_up", DRIVER)
        # Release detection now uses hw_reset + image variance rather than a
        # counted-confirm loop; FTE4800_RELEASE_CONFIRM was intentionally removed.
        self.assertIn("fte4800_hw_reset", DRIVER)
        self.assertIn("for (;;)", DRIVER)
        self.assertIn("FTE4800_POLL_MS", DRIVER)
        self.assertNotIn("FTE4800_FINGER_WAIT_MAX", DRIVER)

    def test_idle_poll_rate_is_bounded_after_overheat_reproduction(self):
        self.assertIn("#define FTE4800_POLL_MS             1000", DRIVER)
        self.assertNotIn("#define FTE4800_POLL_MS              50", DRIVER)

    def test_initial_release_is_confirmed_before_first_stage(self):
        # The driver now calls fte4800_hw_reset() before the enrollment loop to
        # blank the image buffer. wait_finger_up is no longer used at startup
        # (it would redundantly reset+check immediately after open already reset).
        hw_reset = DRIVER.index("fte4800_hw_reset (self);")
        loop = DRIVER.index("while (self->enroll_count < FTE4800_ENROLL_STAGES)")
        self.assertLess(hw_reset, loop,
                        "hw_reset must be called before the enrollment loop")

    def test_stage_only_advances_at_accept_point(self):
        accept = DRIVER.index("/* ACCEPT: this is the only place where an enrollment stage advances. */")
        increment = DRIVER.index("self->enroll_count++;", accept)
        progress = DRIVER.index("fpi_device_enroll_progress (FP_DEVICE (self),", increment)
        self.assertGreater(increment, accept)
        self.assertGreater(progress, increment)

    def test_all_operation_tasks_are_cancellable(self):
        self.assertIn("g_task_new (dev, fpi_device_get_cancellable (dev), fte4800_enroll_done", DRIVER)
        self.assertIn("g_task_new (dev, fpi_device_get_cancellable (dev), fte4800_verify_done", DRIVER)
        # Identify is not registered (fprintd uses it for silent pre-flight which
        # hangs enrollment UX); only enroll and verify are exported.
        self.assertNotIn("fte4800_identify_done", DRIVER)

    def test_patch_contains_canonical_state_machine_and_no_unproven_irq_path(self):
        self.assertIn("WAIT_DOWN", PATCH)
        self.assertIn("WAIT_UP", PATCH)
        self.assertIn("freshly triggered FT9368 frame", PATCH)
        self.assertIn("FTE4800_POLL_MS             1000", PATCH)
        self.assertNotIn("FTE4800_IOCTL_IRQ_ENABLE", PATCH)
        self.assertNotIn("FTE4800_FALLBACK_SCAN_MS", PATCH)


if __name__ == "__main__":
    unittest.main()
