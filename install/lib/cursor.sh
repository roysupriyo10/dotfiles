# Cursor CLI statusline wiring.

run_hook_cursor() {
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

  if ! command -v jq >/dev/null 2>&1; then
    log "warning: jq required for cursor hook — skipping" >&2
    return 0
  fi

  if [ -f "$LIVE" ]; then
    if jq -e --slurpfile shared "$SHARED" '.statusLine == $shared[0].statusLine' "$LIVE" >/dev/null 2>&1; then
      return 0
    fi
    tmp="$(mktemp)"
    jq -s '.[0] * .[1]' "$LIVE" "$SHARED" > "$tmp"
    mv "$tmp" "$LIVE"
  else
    cp "$SHARED" "$LIVE"
  fi
}

run_hook() {
  hook="$1"
  case "$hook" in
    cursor) run_hook_cursor ;;
    *)
      log "unknown hook: $hook" >&2
      return 1
      ;;
  esac
}
