# Antigravity (agy) statusline wiring.

run_hook_agy() {
  AGY_HOME="${AGY_HOME:-$HOME/.gemini/antigravity-cli}"
  SHARED="$DOTFILES/.agy/settings.shared.json"
  SCRIPT="$DOTFILES/.agy/statusline-tokens.sh"
  LIVE="$AGY_HOME/settings.json"

  mkdir -p "$AGY_HOME"
  chmod +x "$SCRIPT"

  if [ -L "$AGY_HOME/statusline-tokens.sh" ] \
      && [ "$(readlink "$AGY_HOME/statusline-tokens.sh")" = "$SCRIPT" ]; then
    :
  else
    ln -sf "$SCRIPT" "$AGY_HOME/statusline-tokens.sh"
  fi

  if ! command -v jq >/dev/null 2>&1; then
    log "warning: jq required for agy hook — skipping" >&2
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
