# Codex supports native footer fields, not the shared agent-statusline command.
run_hook_codex() {
  if ! python3 -c 'import tomllib' >/dev/null 2>&1; then
    log "warning: Python 3.11+ required for Codex statusline setup — skipping" >&2
    return 0
  fi
  python3 "$DOTFILES/install/lib/codex.py" \
    "$DOTFILES/.codex/config.shared.toml" "${CODEX_HOME:-$HOME/.codex}/config.toml"
}
