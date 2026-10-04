"""An isolated interactive terminal for SSH and agent acceptance tests."""

import fcntl
import os
import pty
import select
import signal
import struct
import termios
import time


class Terminal:
    def __init__(self, command, environment, directory=None):
        self.output = bytearray()
        self.pid, self.master = pty.fork()
        if self.pid == 0:
            if directory:
                os.chdir(directory)
            os.execvpe(command[0], command, environment)
        fcntl.ioctl(self.master, termios.TIOCSWINSZ, struct.pack("HHHH", 36, 150, 0, 0))

    def write(self, data):
        os.write(self.master, data)

    def pump(self, seconds=0.05):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if select.select([self.master], [], [], 0.05)[0]:
                try:
                    data = os.read(self.master, 65536)
                except OSError:
                    return
                if not data:
                    return
                self.output.extend(data)
                if b"\x1b[6n" in data:
                    self.write(b"\x1b[1;1R")
                if b"\x1b]11;?" in data:
                    self.write(b"\x1b]11;rgb:0000/0000/0000\x1b\\")

    def close(self):
        try:
            os.killpg(self.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        os.close(self.master)
        os.waitpid(self.pid, 0)

    def __enter__(self):
        return self

    def __exit__(self, *error):
        self.close()
