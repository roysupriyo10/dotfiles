# Cursor CLI statusline wiring. The statusline script itself is
# .local/bin/agent-statusline, mirrored to ~/.local/bin by the manifest.

run_hook_cursor() {
  CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
  SHARED="$DOTFILES/.cursor/cli-config.shared.json"
  LIVE="$CURSOR_HOME/cli-config.json"

  mkdir -p "$CURSOR_HOME"

  # legacy symlink from before the script was shared across CLIs
  [ -L "$CURSOR_HOME/statusline-tokens.sh" ] && rm -f "$CURSOR_HOME/statusline-tokens.sh"

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
    claude) run_hook_claude ;;
    agy) run_hook_agy ;;
    darwin-keymap) run_hook_darwin_keymap ;;
    *)
      log "unknown hook: $hook" >&2
      return 1
      ;;
  esac
}
