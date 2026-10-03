import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "focal_spi.c").read_text()


def function_body(signature: str) -> str:
    start = SOURCE.find(signature)
    if start < 0:
        raise AssertionError(f"missing function: {signature}")
    brace = SOURCE.find("{", start)
    depth = 0
    for i in range(brace, len(SOURCE)):
        if SOURCE[i] == "{":
            depth += 1
        elif SOURCE[i] == "}":
            depth -= 1
            if depth == 0:
                return SOURCE[start:i + 1]
    raise AssertionError(f"unbalanced function: {signature}")


class DriverLifecycleTests(unittest.TestCase):
    def test_request_validation_is_present(self):
        body = function_body("static int focal_validate_request")
        for token in (
            "*rx_len == 0",
            "*tx_len + *rx_len > MAX_BUFF_SIZE",
            "sizeof(*req) + *tx_len > count",
            "*rx_len > count",
        ):
            self.assertIn(token, body)

    def test_read_write_transport_is_direct(self):
        read = function_body("static int focal_spi_read_request")
        self.assertIn("spi_write_then_read", read)
        self.assertIn("spi_read", read)

        write = function_body("static int focal_write_request")
        self.assertIn("spi_write", write)
        self.assertNotIn("rx_len", write)

    def test_irq_is_acpi_edge_active_high(self):
        self.assertIn("IRQF_TRIGGER_RISING | IRQF_ONESHOT", SOURCE)
        self.assertNotIn("IRQF_TRIGGER_HIGH | IRQF_ONESHOT", SOURCE)

    def test_irq_does_not_invent_finger_state(self):
        irq = function_body("static irqreturn_t focal_irq_thread")
        self.assertIn("FOCAL_WAKE_EVENT_INT", irq)
        self.assertNotIn("KEY_", irq)
        self.assertNotIn("TOUCH", irq)

    def test_poll_uses_reference_event_values(self):
        poll = function_body("static __poll_t focal_poll")
        self.assertIn("mask = event;", poll)
        self.assertNotIn("EPOLLIN", poll)

    def test_remove_clears_global_pointer(self):
        remove = function_body("static void focal_remove")
        self.assertIn("focal_ctl.data = NULL;", remove)
        self.assertIn("data->init = -1;", remove)

    def test_all_reference_ioctls_are_explicit(self):
        ioctl = function_body("static long focal_ioctl")
        for token in (
            "case IOCTL_RESET:",
            "case IOCTL_POWER_OFF:",
            "case IOCTL_POWER_ON:",
            "case IOCTL_IRQ_ENABLE:",
            "case IOCTL_LOG_ENABLE:",
            "case IOCTL_RELEASE_POLL:",
            "case IOCTL_CS_CONTROL:",
            "default:",
        ):
            self.assertIn(token, ioctl)


if __name__ == "__main__":
    unittest.main()
