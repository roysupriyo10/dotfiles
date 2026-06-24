_manifest_dispatch() {
  line=$1
  want_kind=$_manifest_want_kind
  line=$(expand_manifest_line "$line")

  set -- $line
  if [ "$1" = LINUX ] || [ "$1" = DARWIN ]; then
    prefix=$1
    shift
    platform_matches "$prefix" || return 0
  fi

  kind=$1
  shift
  [ "$kind" = "$want_kind" ] || return 0

  target=$1
  manifest_repo_path_ready "$target" || return 0

  case "$kind" in
    LINK)
      ensure_symlink "$DOTFILES/$target" "$2"
      ;;
    MIRROR)
      ensure_mirror "$DOTFILES/$target" "$2"
      ;;
    HOOK)
      run_hook "$target"
      ;;
  esac
}

apply_manifest_kind() {
  _manifest_want_kind=$1
  manifest="$INSTALL_DIR/manifest"
  each_config_line "$manifest" _manifest_dispatch
}

apply_manifest_sync() {
  apply_manifest_kind LINK
  apply_manifest_kind MIRROR
}

apply_manifest_hooks() {
  apply_manifest_kind HOOK
}
