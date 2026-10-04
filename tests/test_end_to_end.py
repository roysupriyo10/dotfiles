"""Opt-in acceptance test: real SSH tunnel, real tmux client, both paste methods."""

import json
import os
from pathlib import Path
import pwd
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "rpaste/tests"))
from test_bridge import png
from terminal_fixture import Terminal


@unittest.skipUnless(
    os.environ.get("RPASTE_E2E") == "1" and sys.platform.startswith("linux"),
    "set RPASTE_E2E=1 for the SSH/tmux acceptance test",
)
class EndToEndTests(unittest.TestCase):
    def test_normal_ssh_image_paste_and_reattachment(self):
        for binary in ("sshd", "ssh-keygen", "tmux", "Xvfb", "sudo"):
            if not shutil.which(binary):
                self.skipTest(f"{binary} is missing")
        if subprocess.run(["sudo", "-n", "true"]).returncode:
            self.skipTest(
                "acceptance test needs passwordless sudo for its isolated sshd"
            )
        with tempfile.TemporaryDirectory(prefix="rpaste-e2e-") as temporary:
            root = Path(temporary)
            root.chmod(0o700)
            name = "rpaste-e2e-" + root.name.rsplit("-", 1)[-1]
            clients = []
            server = None

            def wait_for(predicate, client=None):
                deadline = time.monotonic() + 12
                while not predicate():
                    if time.monotonic() > deadline:
                        log = root / "sshd.log"
                        diagnostic = (
                            log.read_text(errors="replace")[-1200:]
                            if log.exists()
                            else ""
                        )
                        self.fail(
                            "acceptance test timed out: "
                            + diagnostic
                            + repr(bytes(client.output[-1200:]) if client else b"")
                        )
                    if client is not None:
                        client.pump()
                    else:
                        time.sleep(0.02)

            try:
                for key in ("host", "client-key"):
                    subprocess.run(
                        [
                            "ssh-keygen",
                            "-q",
                            "-t",
                            "ed25519",
                            "-N",
                            "",
                            "-f",
                            str(root / key),
                        ],
                        check=True,
                    )
                ready = root / "ready"
                received = root / "input"
                native = root / "native.png"
                agent_pid = root / "agent.pid"
                agent = root / "codex"
                agent.write_text(f"""#!{sys.executable}
import os,subprocess,tty
from pathlib import Path
tty.setraw(0)
os.write(1,b'\\x1b[?2004h')
Path({str(agent_pid)!r}).write_text(str(os.getpid()))
Path({str(ready)!r}).touch()
with open({str(received)!r},'ab',buffering=0) as output:
 while True:
  data=os.read(0,4096)
  output.write(data)
  if b'\\x16' in data:
   image=subprocess.check_output(['/usr/bin/xclip','-selection','clipboard','-t','image/png','-o'])
   Path({str(native)!r}).write_bytes(image)
""")
                agent.chmod(0o700)
                remote = root / "remote.py"
                remote.write_text(f"""
import os,subprocess
from pathlib import Path
os.environ['XDG_STATE_HOME']={str(root / 'remote-state')!r}
command=['tmux','-L',{name!r},'-f','/dev/null']
if subprocess.run(command+['has-session','-t','test'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode:
 subprocess.run(command+['new-session','-d','-s','test',{str(REPO / 'rpaste/rpaste')!r},'run','--',{str(agent)!r}],check=True)
 subprocess.run(command+['set-option','-g','@rpaste-method','path'],check=True)
 action={str(REPO / 'rpaste/rpaste')!r}+' tmux-paste --pane #{{pane_id}} --client #{{client_pid}}'
 subprocess.run(command+['bind-key','-n','C-v','run-shell','-b','-t','#{{pane_id}}',action],check=True)
 subprocess.run(command+['bind-key','V','run-shell','-b','-t','#{{pane_id}}',action+' --method native'],check=True)
os.execvp('tmux',['tmux','-L',{name!r},'attach-session','-t','test'])
""")
                with socket.socket() as listener:
                    listener.bind(("127.0.0.1", 0))
                    port = listener.getsockname()[1]
                user = pwd.getpwuid(os.getuid()).pw_name
                config = root / "sshd.conf"
                config.write_text(f"""Port {port}
ListenAddress 127.0.0.1
HostKey {root / 'host'}
PidFile {root / 'sshd.pid'}
AuthorizedKeysFile {root / 'client-key.pub'}
StrictModes no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
AllowUsers {user}
AcceptEnv RPASTE_SOCKET
AllowStreamLocalForwarding yes
ForceCommand {sys.executable} {remote}
""")
                log = (root / "sshd.log").open("wb")
                server = subprocess.Popen(
                    ["sudo", "-n", shutil.which("sshd"), "-D", "-e", "-f", str(config)],
                    stdout=log,
                    stderr=log,
                    start_new_session=True,
                )
                wait_for(
                    lambda: (root / "sshd.pid").exists() or server.poll() is not None
                )
                self.assertIsNone(server.poll(), (root / "sshd.log").read_text())
                original_pid = None
                for number, color in enumerate((b"\xff\0\0", b"\0\xff\0")):
                    home = root / f"client-{number}"
                    binaries = home / ".local/bin"
                    binaries.mkdir(parents=True)
                    (binaries / "ssh").symlink_to(REPO / ".local/bin/ssh")
                    (binaries / "rpaste").symlink_to(REPO / "rpaste/rpaste")
                    image = home / "clipboard.png"
                    image.write_bytes(png(color))
                    clipboard = binaries / "wl-paste"
                    clipboard.write_text(
                        f"#!{sys.executable}\nimport sys\nfrom pathlib import Path\nsys.stdout.buffer.write(Path({str(image)!r}).read_bytes())\n"
                    )
                    clipboard.chmod(0o700)
                    env = os.environ.copy()
                    env.update(
                        HOME=str(home),
                        XDG_STATE_HOME=str(home / "state"),
                        PATH=str(binaries) + os.pathsep + env["PATH"],
                        TERM="xterm-256color",
                        WAYLAND_DISPLAY="fixture",
                    )
                    env.pop("RPASTE_HOST", None)
                    env.pop("RPASTE_AUTO", None)
                    client = Terminal(
                        [
                            "ssh",
                            "-F",
                            "/dev/null",
                            "-p",
                            str(port),
                            "-i",
                            str(root / "client-key"),
                            "-o",
                            "IdentitiesOnly=yes",
                            "-o",
                            "StrictHostKeyChecking=no",
                            "-o",
                            "UserKnownHostsFile=/dev/null",
                            f"{user}@127.0.0.1",
                        ],
                        env,
                    )
                    clients.append(client)
                    wait_for(lambda: ready.exists(), client)
                    wait_for(
                        lambda: subprocess.check_output(
                            ["tmux", "-L", name, "list-clients"]
                        ).strip(),
                        client,
                    )
                    previous_size = received.stat().st_size if received.exists() else 0
                    client.write(b"\x16")
                    wait_for(
                        lambda: received.exists()
                        and b"\x1b[201~" in received.read_bytes()[previous_size:],
                        client,
                    )
                    data = received.read_bytes()[previous_size:]
                    path = json.loads(
                        data.split(b"\x1b[200~", 1)[1].split(b"\x1b[201~", 1)[0]
                    )
                    self.assertEqual(Path(path).read_bytes(), png(color))
                    self.assertNotIn(b"\r", data)
                    pid_now = agent_pid.read_text()
                    if original_pid is None:
                        original_pid = pid_now
                    self.assertEqual(
                        pid_now, original_pid, "reattachment restarted the agent"
                    )
                    native.unlink(missing_ok=True)
                    client.write(b"\x02V")
                    wait_for(lambda: native.exists(), client)
                    self.assertEqual(native.read_bytes(), png(color))
                    client.write(b"\x02d")
                    wait_for(
                        lambda: not subprocess.check_output(
                            ["tmux", "-L", name, "list-clients"]
                        ).strip(),
                        client,
                    )
                self.assertEqual(
                    len(list((root / "remote-state/rpaste/images").glob("*.png"))), 5
                )
            finally:
                for client in clients:
                    client.close()
                subprocess.run(
                    ["tmux", "-L", name, "kill-server"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                for metadata in root.glob("**/display.json"):
                    try:
                        os.kill(json.loads(metadata.read_text())["pid"], signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                for marker in root.glob("**/source.pid"):
                    try:
                        os.kill(int(marker.read_text()), signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                if server and server.poll() is None:
                    subprocess.run(
                        ["sudo", "-n", "kill", "-TERM", "--", str(-server.pid)],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )
                    server.wait(timeout=5)
                if server:
                    log.close()


if __name__ == "__main__":
    unittest.main()
