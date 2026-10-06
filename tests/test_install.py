from pathlib import Path
import shutil
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

    def run_on_dnf_host_with_homebrew(self, packages, commands):
        script = """
INSTALL_DIR=$2
source "$1/install/lib/pkg.sh"
OS=Linux
log() { :; }
rpm() { return 1; }
sudo() { "$@"; }
dnf() { echo "dnf $*"; }
brew() { :; }
brew_run() { [ "$1" = install ] && echo "brew $*"; }
"""
        with tempfile.TemporaryDirectory(prefix="pkg-install-test-") as temporary:
            # No yay or pacman on this host, whatever the machine running the test has.
            host_bin = Path(temporary) / "bin"
            host_bin.mkdir()
            (host_bin / "awk").symlink_to(shutil.which("awk"))
            (Path(temporary) / "packages").write_text(packages)
            return subprocess.run(
                ["/bin/bash", "-c", script + commands, "test", str(REPO), temporary],
                capture_output=True,
                text=True,
                env={"PATH": str(host_bin)},
            )

    def test_package_names_come_from_the_packages_table(self):
        result = self.run_on_dnf_host_with_homebrew(
            "# <pkg> <brew> <dnf>\nrenamed brew-renamed dnf-renamed\nbrew-only brew-only -\n",
            "pkg_install renamed\npkg_install brew-only\npkg_install unlisted\n"
            "pkg_install unlisted brew-override\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.splitlines(),
            [
                "dnf install -y dnf-renamed",
                "brew install brew-only",
                "brew install unlisted",
                "brew install brew-override",
            ],
        )

    def test_package_no_manager_ships_is_unavailable_and_never_requested(self):
        result = self.run_on_dnf_host_with_homebrew(
            "nowhere - -\n",
            "pkg_available nowhere && echo available\n"
            "pkg_available unlisted && echo 'unlisted available'\n"
            "pkg_install nowhere || echo \"install failed: $?\"\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.splitlines(),
            ["unlisted available", "install failed: 1"],
        )

    def test_host_password_drop_in_is_found_only_when_it_turns_passwords_on(self):
        script = """
source "$1/install/lib/ssh.sh"
_ssh_host_password_dropin "$2" || echo none
"""
        cases = [
            ({}, "none"),
            ({"40-hardening.conf": "PasswordAuthentication no\n"}, "none"),
            ({"50-host.conf": "#PasswordAuthentication yes\n"}, "none"),
            ({"40-host.conf": "PasswordAuthentication yes\n"}, "40-host.conf"),
            ({"99-host.conf": "  kbdinteractiveauthentication yes\n"}, "99-host.conf"),
        ]
        for files, expected in cases:
            with self.subTest(files=files), tempfile.TemporaryDirectory() as temporary:
                for name, content in files.items():
                    (Path(temporary) / name).write_text(content)
                result = subprocess.run(
                    ["bash", "-c", script, "test", str(REPO), temporary],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(Path(result.stdout.strip()).name, expected)

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
