# Antigravity (agy) statusline wiring. The statusline script itself is
# .local/bin/agent-statusline, mirrored to ~/.local/bin by the manifest.

run_hook_agy() {
  AGY_HOME="${AGY_HOME:-$HOME/.gemini/antigravity-cli}"
  SHARED="$DOTFILES/.agy/settings.shared.json"
  LIVE="$AGY_HOME/settings.json"

  mkdir -p "$AGY_HOME"

  # legacy symlink from before the script was shared across CLIs
  [ -L "$AGY_HOME/statusline-tokens.sh" ] && rm -f "$AGY_HOME/statusline-tokens.sh"

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
