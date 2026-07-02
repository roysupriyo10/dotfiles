# Claude Code statusline wiring.

run_hook_claude() {
  CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
  SHARED="$DOTFILES/.claude/settings.shared.json"
  SCRIPT="$DOTFILES/.claude/statusline-tokens.sh"
  LIVE="$CLAUDE_HOME/settings.json"

  mkdir -p "$CLAUDE_HOME"
  chmod +x "$SCRIPT"

  if [ -L "$CLAUDE_HOME/statusline-tokens.sh" ] \
      && [ "$(readlink "$CLAUDE_HOME/statusline-tokens.sh")" = "$SCRIPT" ]; then
    :
  else
    ln -sf "$SCRIPT" "$CLAUDE_HOME/statusline-tokens.sh"
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log "warning: jq required for claude hook — skipping" >&2
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
