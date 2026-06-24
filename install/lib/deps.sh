# Manifest ↔ submodule dependency map (install/submodule-deps).

deps_file() {
  printf '%s/submodule-deps' "$INSTALL_DIR"
}

manifest_submodules_for() {
  repo_path=$1
  _deps_repo_path=$repo_path
  _deps_accum=
  file=$(deps_file)
  [ -f "$file" ] || return 0

  _deps_collect() {
    line=$1
    set -- $line
    [ "$1" = "$_deps_repo_path" ] || return 0
    shift
    for sub in "$@"; do
      _deps_accum="$_deps_accum $sub"
    done
  }

  each_config_line "$file" _deps_collect
  # shellcheck disable=SC2086
  set -- $_deps_accum
  printf '%s\n' "$@"
}

manifest_repo_path_ready() {
  repo_path=$1
  subs=$(manifest_submodules_for "$repo_path")
  [ -n "$subs" ] || return 0

  for sub in $subs; do
    if ! submodule_ready "$sub"; then
      log "skipping $repo_path — submodule $sub: $(submodule_status_reason "$sub")" >&2
      return 1
    fi
  done
  return 0
}
