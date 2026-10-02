import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADER = ROOT / "protocol" / "fte4800_protocol.h"


class ProtocolConstantTests(unittest.TestCase):
    def test_native_frame_contract(self):
        text = " ".join(HEADER.read_text().split())
        required = (
            "#define FTE4800_IMAGE_WIDTH 64U",
            "#define FTE4800_IMAGE_HEIGHT 80U",
            "FTE4800_NATIVE_IMAGE_BYTES",
            "FTE4800_COMPAT_IMAGE_BYTES",
            "#define FTE4800_IMAGE_HEADER_BYTES 7U",
            "#define FTE4800_IMAGE_REG 0x90U",
            "#define FTE4800_IMAGE_FLAG 0x80U",
        )
        for token in required:
            self.assertIn(token, text)


if __name__ == "__main__":
    unittest.main()
