from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def test_package_failure_is_not_reported_as_success(self):
        script = """
source "$1/install/lib/pkg.sh"
log() { :; }
pacman() { return 1; }
yay() { return 42; }
if pkg_yay example; then exit 0; else exit "$?"; fi
"""
        result = subprocess.run(["bash", "-c", script, "test", str(REPO)])
        self.assertEqual(result.returncode, 42)

    def test_path_only_setup_does_not_request_native_packages_or_edit_profiles(self):
        script = """
DOTFILES=$1
OS=Linux
RPASTE_NATIVE=0
unset DISPLAY WAYLAND_DISPLAY
source "$DOTFILES/install/lib/rpaste.sh"
install_rpaste_ssh() { :; }
log() { :; }
pkg_install() { echo "unexpected package install"; return 1; }
DOTFILES=$2
run_hook_rpaste
"""
        with tempfile.TemporaryDirectory(prefix="rpaste-install-test-") as temporary:
            bridge_dir = Path(temporary) / "rpaste"
            bridge_dir.mkdir()
            bridge = bridge_dir / "rpaste"
            bridge.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            bridge.chmod(0o700)
            (bridge_dir / "rpaste_agent.py").touch()
            result = subprocess.run(
                ["bash", "-c", script, "test", str(REPO), temporary],
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.splitlines(),
            ["install", "--no-profile", "--no-check", "--no-native"],
        )


if __name__ == "__main__":
    unittest.main()
