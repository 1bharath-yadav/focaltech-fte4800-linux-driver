import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADER = ROOT / "protocol" / "fte4800_protocol.h"


class ProtocolConstantTests(unittest.TestCase):
    def setUp(self):
        self.text = " ".join(HEADER.read_text().split())

    def test_spi_configuration_matches_acpi(self):
        self.assertIn("#define FTE4800_SPI_MODE 0U", self.text)
        self.assertIn("#define FTE4800_SPI_HZ 1000000U", self.text)

    def test_reset_value_is_explicit(self):
        self.assertIn("#define FTE4800_RESET_ASSERT_MS 10U", self.text)

    def test_identity_contract(self):
        self.assertIn("#define FTE4800_COMPAT_READ_REQUEST 0x08U", self.text)
        self.assertIn("#define FTE4800_COMPAT_READ_TAG 0xF7U", self.text)
        self.assertIn("#define FTE4800_INFO_REG 0x91U", self.text)
        self.assertIn("#define FTE4800_INFO_FLAG 0x80U", self.text)
        self.assertIn("#define FTE4800_INFO_PAYLOAD_BYTES 32U", self.text)
        self.assertIn("#define FTE4800_INFO_HEADER_BYTES 7U", self.text)
        self.assertIn("#define FTE4800_CHIP_ID 0x9368U", self.text)
        self.assertIn("#define FTE4800_INFO_CHIP_OFFSET 0x13U", self.text)

    def test_non_identity_protocol_constants_are_not_present(self):
        for token in (
            "FTE4800_IMAGE_REG",
            "FTE4800_COMPAT_BULK",
            "FTE4800_COMPAT_INT_STATUS_ADDR",
            "FTE4800_COMPAT_INT_CLEAR_ADDR",
        ):
            self.assertNotIn(token, self.text)


if __name__ == "__main__":
    unittest.main()
