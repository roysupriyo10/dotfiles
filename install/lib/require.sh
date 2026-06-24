# require_cmd <name> [context] — returns 0 if present, else warns and returns 1.

require_cmd() {
  cmd=$1
  ctx=${2:-}
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if [ -n "$ctx" ]; then
    log "warning: $cmd required for $ctx — skipping" >&2
  else
    log "warning: $cmd required — skipping" >&2
  fi
  return 1
}
