import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepositoryCleanupTests(unittest.TestCase):
    def test_no_tracked_build_artifacts_or_pyc(self):
        result = subprocess.run(
            ["git", "ls-files"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        files = result.stdout.splitlines()
        forbidden_extensions = (".o", ".ko", ".pyc", ".symvers", ".order", ".cmd")
        tracked_binaries = [
            f for f in files if any(f.endswith(ext) for ext in forbidden_extensions)
        ]
        self.assertEqual(
            tracked_binaries,
            [],
            f"Repository contains tracked build artifacts: {tracked_binaries}",
        )

    def test_public_tree_excludes_local_artifacts(self):
        forbidden_paths = (
            "archive/",
            "extracted-windows-fw/",
            "dataset/",
            "docs/re-dumps/",
            "docs/superpowers/",
        )
        files = subprocess.run(
            ["git", "ls-files"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        ).stdout.splitlines()
        for prefix in forbidden_paths:
            self.assertFalse(
                any(f == prefix.rstrip("/") or f.startswith(prefix) for f in files),
                f"Private artifact path is tracked: {prefix}",
            )

    def test_gitignore_ignores_build_artifacts(self):
        gitignore = (ROOT / ".gitignore").read_text()
        required_patterns = (
            "*.o",
            "*.ko",
            "*.mod",
            "*.mod.c",
            "__pycache__/",
            "*.pyc",
            "Module.symvers",
            "modules.order",
        )
        for pattern in required_patterns:
            self.assertIn(pattern, gitignore)

    def test_active_driver_and_tools_have_no_synthetic_residue(self):
        active_files = [
            ROOT / "focal_spi.c",
            ROOT / "protocol" / "fte4800_protocol.h",
            ROOT / "tools" / "fte4800_selftest.py",
            ROOT / "tools" / "fte4800_capture.py",
            ROOT / "tools" / "live-finger-monitor.py",
        ]
        forbidden_tokens = (
            "generate_synthetic_frame",
            "stage_shifts",
            "fp_sqrt",
            "generate_fingerprint_frame",
        )
        for path in active_files:
            text = path.read_text()
            for token in forbidden_tokens:
                self.assertNotIn(
                    token,
                    text,
                    f"Active file {path.name} contains forbidden token '{token}'",
                )


if __name__ == "__main__":
    unittest.main()
