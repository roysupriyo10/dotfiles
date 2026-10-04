"""Opt-in native/path attachment checks against the installed agent binaries."""

import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "rpaste"))
sys.path.insert(0, str(REPO / "rpaste/tests"))
from rpaste_display import clipboard_env
from test_bridge import png
from terminal_fixture import Terminal


@unittest.skipUnless(
    os.environ.get("RPASTE_AGENT_UI") == "1" and sys.platform.startswith("linux"),
    "set RPASTE_AGENT_UI=1 for installed-agent UI checks",
)
class AgentUiTests(unittest.TestCase):
    def test_each_agent_attaches_native_and_unicode_path_images(self):
        for command in ("Xvfb", "codex", "claude"):
            if not shutil.which(command):
                self.skipTest(f"{command} is not installed")
        real_home = Path.home()
        for path in (
            real_home / ".claude/.credentials.json",
            real_home / ".codex/auth.json",
        ):
            if not path.is_file():
                self.skipTest("agent sign-in files are missing")
        with tempfile.TemporaryDirectory(prefix="rpaste-agent-ui-") as temporary:
            root = Path(temporary)
            root.chmod(0o700)
            image = root / "reference λ.png"
            image.write_bytes(png())
            environment = clipboard_env(root / "native")
            environment["RPASTE_NATIVE_STATE"] = str(root / "native")
            for key in ("WAYLAND_DISPLAY", "TMUX", "TMUX_PANE"):
                environment.pop(key, None)
            subprocess.run(
                [
                    "/usr/bin/xclip",
                    "-selection",
                    "clipboard",
                    "-t",
                    "image/png",
                    "-i",
                    str(image),
                ],
                env=environment,
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                for agent in ("claude", "codex"):
                    with self.subTest(agent=agent):
                        work = root / agent
                        work.mkdir()
                        home = work / "home"
                        home.mkdir()
                        env = environment.copy()
                        env.update(
                            HOME=str(home),
                            TERM="xterm-256color",
                            XDG_STATE_HOME=str(work / "state"),
                            XDG_CONFIG_HOME=str(home / ".config"),
                            XDG_DATA_HOME=str(home / ".local/share"),
                            XDG_CACHE_HOME=str(home / ".cache"),
                            CLAUDECODE="",
                            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1",
                        )
                        if agent == "claude":
                            config = home / ".claude"
                            config.mkdir()
                            env["CLAUDE_CONFIG_DIR"] = str(config)
                            shutil.copyfile(
                                real_home / ".claude/.credentials.json",
                                config / ".credentials.json",
                            )
                            settings = json.loads(
                                (real_home / ".claude.json").read_text()
                            )
                            settings.update(
                                hasCompletedOnboarding=True, autoUpdates=False
                            )
                            settings["projects"] = {
                                str(work): {"hasTrustDialogAccepted": True}
                            }
                            for target in (
                                home / ".claude.json",
                                config / ".claude.json",
                            ):
                                target.write_text(json.dumps(settings))
                                target.chmod(0o600)
                            command = [shutil.which(agent)]
                        else:
                            config = home / ".codex"
                            config.mkdir()
                            env["CODEX_HOME"] = str(config)
                            for name in ("auth.json", "models_cache.json"):
                                source = real_home / ".codex" / name
                                if source.is_file():
                                    shutil.copyfile(source, config / name)
                                    (config / name).chmod(0o600)
                            (config / "config.toml").write_text(
                                'model="gpt-6"\ncheck_for_update_on_startup=false\n'
                            )
                            command = [
                                shutil.which(agent),
                                "--no-daemon",
                                "--no-alt-screen",
                                "-C",
                                str(work),
                                "-a",
                                "never",
                                "-s",
                                "read-only",
                            ]
                        with Terminal(command, env, work) as terminal:
                            terminal.pump(6)
                            terminal.write(b"\x16")
                            terminal.pump(3)
                            terminal.write(
                                b"\x1b[200~"
                                + json.dumps(str(image), ensure_ascii=False).encode()
                                + b"\x1b[201~"
                            )
                            terminal.pump(3)
                            output = terminal.output.decode(errors="replace")
                            output = re.sub(
                                r"\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]",
                                "",
                                output,
                            )
                            output = re.sub(r"\s", "", output)
                            self.assertIn(
                                "[Image#1]", output, "native image did not attach"
                            )
                            self.assertIn(
                                "[Image#2]", output, "Unicode path image did not attach"
                            )
            finally:
                server = json.loads(
                    (root / "native/clipboard/display.json").read_text()
                )
                os.kill(server["pid"], signal.SIGTERM)


if __name__ == "__main__":
    unittest.main()
