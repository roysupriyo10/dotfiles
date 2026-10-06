import base64
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from terminal_fixture import Terminal

REPO = Path(__file__).resolve().parents[1]
CLIP = str(REPO / ".local/bin/clip")
BASH = shutil.which("bash")

# Stand-ins that record what they were asked to copy instead of copying it.
FAKE_TMUX = """#!/bin/sh
case "$1" in
  show-environment) [ -z "$FAKE_TMUX_SSH" ] || echo "SSH_CONNECTION=$FAKE_TMUX_SSH" ;;
  load-buffer) [ "$2" = -w ] && cat > "$CAPTURE.tmux" ;;
esac
"""
FAKE_NATIVE = """#!/bin/sh
cat > "$CAPTURE.native"
"""


class ClipTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="clip-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        tools = self.root / "bin"
        tools.mkdir()
        for name in ("cat", "base64", "tr", "uname", "grep"):
            (tools / name).symlink_to(shutil.which(name))
        for name, body in (
            ("tmux", FAKE_TMUX),
            ("pbcopy", FAKE_NATIVE),
            ("wl-copy", FAKE_NATIVE),
        ):
            (tools / name).write_text(body)
            (tools / name).chmod(0o700)
        self.environment = {"PATH": str(tools), "CAPTURE": str(self.root / "copied")}

    def clip(self, stdin, *arguments, **environment):
        return subprocess.run(
            [BASH, CLIP, *arguments],
            input=stdin,
            capture_output=True,
            env={**self.environment, **environment},
        )

    def copied(self, route):
        return (self.root / f"copied.{route}").read_bytes()

    def test_remote_tmux_pane_copies_through_tmux_even_with_a_local_tool(self):
        result = self.clip(
            b"/home/me\n", TMUX="x", FAKE_TMUX_SSH="1.2.3.4", WAYLAND_DISPLAY="w"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.copied("tmux"), b"/home/me")
        self.assertFalse((self.root / "copied.native").exists())

    def test_only_a_single_line_loses_its_trailing_newline(self):
        self.clip(b"one\ntwo\n", TMUX="x", FAKE_TMUX_SSH="1.2.3.4")
        self.assertEqual(self.copied("tmux"), b"one\ntwo\n")
        self.clip(None, "some", "text", TMUX="x", FAKE_TMUX_SSH="1.2.3.4")
        self.assertEqual(self.copied("tmux"), b"some text")

    def test_local_session_uses_the_native_tool_even_inside_tmux(self):
        result = self.clip(b"local\n", TMUX="x", WAYLAND_DISPLAY="w")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.copied("native"), b"local")
        self.assertFalse((self.root / "copied.tmux").exists())

    def test_empty_input_copies_nothing(self):
        result = self.clip(b"", TMUX="x", FAKE_TMUX_SSH="1.2.3.4")
        self.assertEqual(result.returncode, 1)
        self.assertFalse((self.root / "copied.tmux").exists())

    def test_bare_ssh_writes_osc_52_to_the_terminal(self):
        text = "héllo wörld"
        environment = {**self.environment, "SSH_CONNECTION": "1.2.3.4 1 5.6.7.8 22"}
        with Terminal([BASH, CLIP, text], environment) as terminal:
            terminal.pump(1)
            expected = b"\x1b]52;c;" + base64.b64encode(text.encode()) + b"\x07"
            self.assertIn(expected, bytes(terminal.output))


if __name__ == "__main__":
    unittest.main()
