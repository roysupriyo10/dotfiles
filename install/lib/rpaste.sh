run_hook_rpaste() {
  if ! command -v rpaste >/dev/null 2>&1; then
    log "rpaste not in PATH — skipping hook" >&2
    return 0
  fi
  rpaste install 2>&1 | while IFS= read -r line; do log "$line"; done
}
