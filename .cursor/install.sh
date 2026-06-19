#!/bin/sh
# Wire dotfiles Cursor CLI bits into ~/.cursor (idempotent).
set -e
DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
SHARED="$DOTFILES/.cursor/cli-config.shared.json"
SCRIPT="$DOTFILES/.cursor/statusline-tokens.sh"
LIVE="$CURSOR_HOME/cli-config.json"

mkdir -p "$CURSOR_HOME"
chmod +x "$SCRIPT"
ln -sf "$SCRIPT" "$CURSOR_HOME/statusline-tokens.sh"

if ! command -v jq >/dev/null; then
  echo "install.sh: jq required to merge cli-config.shared.json" >&2
  exit 1
fi

if [ -f "$LIVE" ]; then
  tmp="$(mktemp)"
  jq -s '.[0] * .[1]' "$LIVE" "$SHARED" > "$tmp"
  mv "$tmp" "$LIVE"
else
  cp "$SHARED" "$LIVE"
fi

echo "install.sh: linked statusline and merged statusLine into $LIVE"
