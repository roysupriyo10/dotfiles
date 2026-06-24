apply_manifest_kind() {
  want_kind="$1"
  manifest="$INSTALL_DIR/manifest"
  [ -f "$manifest" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$line" ] && continue
    line=$(expand_manifest_line "$line")

    set -- $line
    if [ "$1" = LINUX ] || [ "$1" = DARWIN ]; then
      prefix="$1"
      shift
      platform_matches "$prefix" || continue
    fi

    kind="$1"
    shift
    [ "$kind" = "$want_kind" ] || continue

    repo_path=$1
    manifest_repo_path_ready "$repo_path" || continue

    case "$kind" in
      LINK)
        ensure_symlink "$DOTFILES/$repo_path" "$2"
        ;;
      MIRROR)
        ensure_mirror "$DOTFILES/$repo_path" "$2"
        ;;
      HOOK)
        run_hook "$repo_path"
        ;;
    esac
  done < "$manifest"
}

apply_manifest_sync() {
  apply_manifest_kind LINK
  apply_manifest_kind MIRROR
}

apply_manifest_hooks() {
  apply_manifest_kind HOOK
}
