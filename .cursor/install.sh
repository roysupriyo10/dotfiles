#!/bin/sh
# Wire dotfiles Cursor CLI bits into ~/.cursor (idempotent).
set -e

DOTFILES="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
SHARED="$DOTFILES/.cursor/cli-config.shared.json"
SCRIPT="$DOTFILES/.cursor/statusline-tokens.sh"
LIVE="$CURSOR_HOME/cli-config.json"

mkdir -p "$CURSOR_HOME"
chmod +x "$SCRIPT"

if [ -L "$CURSOR_HOME/statusline-tokens.sh" ] \
    && [ "$(readlink "$CURSOR_HOME/statusline-tokens.sh")" = "$SCRIPT" ]; then
  :
else
  ln -sf "$SCRIPT" "$CURSOR_HOME/statusline-tokens.sh"
fi

if ! command -v jq >/dev/null; then
  echo "install.sh: jq required to merge cli-config.shared.json" >&2
  exit 1
fi

if [ -f "$LIVE" ]; then
  if jq -e --slurpfile shared "$SHARED" '.statusLine == $shared[0].statusLine' "$LIVE" >/dev/null 2>&1; then
    exit 0
  fi
  tmp="$(mktemp)"
  jq -s '.[0] * .[1]' "$LIVE" "$SHARED" > "$tmp"
  mv "$tmp" "$LIVE"
else
  cp "$SHARED" "$LIVE"
fi
