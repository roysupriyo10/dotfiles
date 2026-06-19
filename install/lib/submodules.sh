# Init missing submodules only. Never reset deviated (+/U) or dirty checkouts.

ensure_submodules() {
  git -C "$DOTFILES" submodule status --recursive 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue

    flag=$(printf '%s' "$line" | cut -c1)
    path=$(printf '%s' "$line" | awk '{print $2}')
    [ -z "$path" ] && continue

    case "$flag" in
      -)
        log "initializing submodule $path..."
        git -C "$DOTFILES" submodule update --init "$path"
        ;;
    esac
  done
}
