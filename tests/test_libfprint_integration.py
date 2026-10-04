import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DRIVER = (ROOT / "libfprint" / "drivers" / "fte4800.c").read_text()
VENDOR_ENGINE = (ROOT / "libfprint" / "drivers" / "vendor-engine.c").read_text()
VENDOR_HEADER = (ROOT / "libfprint" / "drivers" / "vendor-engine.h").read_text()
PATCH = (ROOT / "libfprint-patches" / "0001-native-fte4800-ft9368-driver.patch").read_text()


class LibfprintIntegrationTests(unittest.TestCase):
    def test_canonical_vendor_engine_sources_exist(self):
        self.assertIn("FocalTech FTE4800 / FT9368", DRIVER)
        self.assertIn("ft_engine_open", DRIVER)
        self.assertIn("WbioQueryEngineInterface", VENDOR_ENGINE)
        self.assertIn("ft_engine_verify", VENDOR_HEADER)

    def test_patch_contains_native_capture_trigger(self):
        self.assertIn("0x00, 0x3B", PATCH)
        self.assertIn("60 * 1000", PATCH)
        self.assertIn("0x90, 0x80, 0x14, 0x00", PATCH)

    def test_patch_contains_vendor_engine_source(self):
        self.assertIn("vendor-engine.c", PATCH)
        self.assertIn("vendor-engine.h", PATCH)
        self.assertIn("drivers/vendor-engine.c", PATCH)

    def test_patch_does_not_patch_system_library_offsets(self):
        for token in ("0x66bdf", "0x66c11", "0x88147", "0x88174", "0x148040"):
            self.assertNotIn(token, PATCH)

    def test_stores_opaque_vendor_template(self):
        self.assertIn("#define FTE4800_ENROLL_STAGES         12", DRIVER)
        self.assertIn('FTE4800_VENDOR_MAGIC       "FTV1"', DRIVER)
        self.assertIn("FTE4800_VENDOR_MAX_TEMPLATE", DRIVER)
        self.assertIn("/usr/lib/focaltech-fte4800/ftWbioEngineAdapter.dll", DRIVER)
        self.assertIn("ft_engine_enroll_commit", DRIVER)
        self.assertIn("fte4800_get_print_template", DRIVER)

    def test_uses_standard_libfprint_retry_codes(self):
        self.assertIn("FP_DEVICE_RETRY_GENERAL", DRIVER)
        self.assertIn("fpi_device_enroll_progress", DRIVER)

    def test_press_release_state_gates_are_explicit(self):
        self.assertIn("fte4800_wait_finger_down", DRIVER)
        self.assertIn("fte4800_wait_finger_up", DRIVER)
        self.assertIn("fte4800_hw_reset", DRIVER)
        self.assertIn("for (;;)", DRIVER)
        self.assertIn("FTE4800_POLL_MS", DRIVER)
        self.assertNotIn("FTE4800_FINGER_WAIT_MAX", DRIVER)

    def test_idle_poll_rate_is_bounded(self):
        self.assertIn("#define FTE4800_POLL_MS             250", DRIVER)
        self.assertNotIn("#define FTE4800_POLL_MS              50", DRIVER)

    def test_initial_reset_precedes_enrollment_loop(self):
        hw_reset = DRIVER.index("fte4800_hw_reset (self);")
        loop = DRIVER.index("while (self->enroll_count < FTE4800_ENROLL_STAGES)")
        self.assertLess(hw_reset, loop)

    def test_stage_advances_only_after_vendor_update(self):
        update = DRIVER.index("ft_engine_enroll_update")
        increment = DRIVER.index("self->enroll_count++;", update)
        progress = DRIVER.index("fpi_device_enroll_progress (FP_DEVICE (self),", increment)
        self.assertGreater(increment, update)
        self.assertGreater(progress, increment)

    def test_all_operation_tasks_are_cancellable(self):
        self.assertIn("g_task_run_in_thread (task, fte4800_enroll_thread)", DRIVER)
        self.assertIn("g_task_run_in_thread (task, fte4800_verify_thread)", DRIVER)
        self.assertIn("fpi_device_get_cancellable (dev)", DRIVER)
        self.assertNotIn("fte4800_identify_done", DRIVER)

    def test_vendor_engine_crypto_is_not_bypassed(self):
        self.assertIn("sha256_block", VENDOR_ENGINE)
        self.assertIn("sha256_final", VENDOR_ENGINE)
        self.assertIn("BCryptHashData", VENDOR_ENGINE)
        self.assertNotIn("BCryptVerifySignature", VENDOR_ENGINE)

    def test_vendor_teb_refreshes_current_thread_stack_bounds(self):
        self.assertIn("pthread_getattr_np", VENDOR_ENGINE)
        self.assertIn("pthread_attr_getstack", VENDOR_ENGINE)
        self.assertIn("StackBase", VENDOR_ENGINE)
        self.assertIn("StackLimit", VENDOR_ENGINE)
        self.assertIn("arm_teb_for_current_thread", VENDOR_ENGINE)


    def test_no_old_frame_matcher_remains_active(self):
        self.assertNotIn("fte4800_match_frames", DRIVER)
        self.assertNotIn("FTE4800_MATCH_THRESHOLD", DRIVER)
        self.assertNotIn("FTE2", DRIVER)

    def test_patch_contains_vendor_state_machine(self):
        self.assertIn("WAIT_DOWN", PATCH)
        self.assertIn("WAIT_UP", PATCH)
        self.assertIn("FTE4800_POLL_MS             250", PATCH)
        self.assertIn("FTV1", PATCH)
        self.assertIn("vendor-engine.c", PATCH)


if __name__ == "__main__":
    unittest.main()
