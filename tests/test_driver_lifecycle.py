import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "focal_spi.c").read_text()


def function_body(name: str) -> str:
    start = SOURCE.index(name)
    tail = SOURCE[start:]
    return tail[:tail.index("\n}\n") + 3]


class DriverLifecycleTests(unittest.TestCase):
    def test_only_irq_creates_touch_state(self):
        compat = function_body("static int focal_compat_write")
        self.assertNotIn("data->sensor_state = FOCAL_STATE_TOUCH", compat)

    def test_poll_is_nonblocking_and_uses_poll_wait(self):
        poll = function_body("static __poll_t focal_poll")
        self.assertIn("poll_wait", poll)
        self.assertNotIn("wait_event", poll)

    def test_poll_serializes_event_state(self):
        poll = function_body("static __poll_t focal_poll")
        self.assertIn("mutex_lock(&data->lock)", poll)
        self.assertIn("mutex_unlock(&data->lock)", poll)

    def test_irq_uses_rising_edge(self):
        self.assertIn("IRQF_TRIGGER_RISING | IRQF_ONESHOT", SOURCE)
        self.assertNotIn("IRQF_TRIGGER_HIGH | IRQF_ONESHOT", SOURCE)

    def test_remove_clears_global_pointer(self):
        remove = function_body("static void focal_remove")
        self.assertIn("focal_ctl.data = NULL", remove)
        self.assertIn("data->init = -1", remove)

    def test_copy_lengths_are_checked(self):
        self.assertIn("sizeof(*req) + tx_len > count", SOURCE)
        self.assertIn("tx_len + rx_len > MAX_BUFF_SIZE", SOURCE)


if __name__ == "__main__":
    unittest.main()
