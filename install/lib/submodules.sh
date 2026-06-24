# Submodule helpers — init missing only; never reset deviated (+/U) checkouts.

# Flag from `git submodule status`: - (missing), + (deviated), U (merge), space (ok).
submodule_flag() {
  path=$1
  line=$(git -C "$DOTFILES" submodule status -- "$path" 2>/dev/null) || return 1
  [ -n "$line" ] || return 1
  printf '%s' "$line" | cut -c1
}

submodule_status_reason() {
  path=$1
  flag=$(submodule_flag "$path") || {
    printf 'not registered'
    return 0
  }
  case "$flag" in
    -) printf 'not initialized' ;;
    +) printf 'checkout differs from recorded commit' ;;
    U) printf 'merge conflict' ;;
    ' ')
      if [ -d "$DOTFILES/$path/.git" ] || [ -f "$DOTFILES/$path/.git" ]; then
        if git -C "$DOTFILES/$path" diff --quiet HEAD 2>/dev/null \
            && git -C "$DOTFILES/$path" diff --cached --quiet HEAD 2>/dev/null; then
          printf 'ok'
        else
          printf 'dirty working tree'
        fi
      else
        printf 'path missing'
      fi
      ;;
    *) printf 'unknown state (%s)' "$flag" ;;
  esac
}

submodule_ready() {
  path=$1
  reason=$(submodule_status_reason "$path")
  [ "$reason" = ok ]
}

submodules_ready() {
  for path in "$@"; do
    if ! submodule_ready "$path"; then
      return 1
    fi
  done
  return 0
}

ensure_submodules() {
  status=$(git -C "$DOTFILES" submodule status --recursive 2>/dev/null) || return 0
  [ -n "$status" ] || return 0

  printf '%s\n' "$status" | while IFS= read -r line; do
    [ -z "$line" ] && continue

    flag=$(printf '%s' "$line" | cut -c1)
    path=$(printf '%s' "$line" | awk '{print $2}')
    [ -z "$path" ] && continue

    case "$flag" in
      -)
        log "initializing submodule $path..."
        if ! git -C "$DOTFILES" submodule update --init "$path"; then
          log "warning: failed to init submodule $path ($(submodule_status_reason "$path"))" >&2
        fi
        ;;
    esac
  done
}
