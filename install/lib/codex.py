#!/usr/bin/env python3
"""Merge the shared Codex status line while preserving other config and comments."""
import copy
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import tomllib


def merge(text, items):
    before = tomllib.loads(text)
    if before.get('tui', {}).get('status_line') == items:
        return text
    value = 'status_line = ' + json.dumps(items) + '\n'
    table = re.search(r'^\[tui\]\s*(?:#.*)?$', text, re.M)
    if table:
        start = text.find('\n', table.start())
        start = len(text) if start < 0 else start + 1
        following = re.search(r'^\s*\[', text[start:], re.M)
        end = start + following.start() if following else len(text)
        body = text[start:end]
        assignment = re.compile(r'^\s*status_line\s*=\s*\[.*?\][ \t]*(?:#[^\n]*)?(?:\n|$)', re.M | re.S)
        if 'status_line' in before.get('tui', {}):
            body, count = assignment.subn(value, body, count=1)
            if count != 1:
                raise ValueError('Unsupported status_line syntax; configuration left unchanged')
        else:
            body = value + body
        result = text[:start] + ('\n' if start and text[start-1] != '\n' else '') + body + text[end:]
    else:
        result = text.rstrip() + '\n\n[tui]\n' + value
    expected = copy.deepcopy(before)
    expected.setdefault('tui', {})['status_line'] = items
    if tomllib.loads(result) != expected:
        raise ValueError('Merge would alter another setting; configuration left unchanged')
    return result


def main():
    shared, live = map(Path, sys.argv[1:])
    items = tomllib.loads(shared.read_text())['tui']['status_line']
    live = live.expanduser().resolve()
    original = live.read_text() if live.exists() else ''
    updated = merge(original, items)
    if updated == original:
        return
    live.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(live.stat().st_mode) if live.exists() else 0o600
    fd, tmp = tempfile.mkstemp(prefix='.codex-config-', dir=live.parent)
    try:
        with os.fdopen(fd, 'w') as f:
            os.fchmod(f.fileno(), mode)
            f.write(updated)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, live)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


if __name__ == '__main__':
    main()
