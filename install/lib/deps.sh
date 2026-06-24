# Manifest ↔ submodule dependency map (install/submodule-deps).

deps_file() {
  printf '%s/submodule-deps' "$INSTALL_DIR"
}

manifest_submodules_for() {
  repo_path=$1
  file=$(deps_file)
  [ -f "$file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$line" ] && continue

    set -- $line
    [ "$1" = "$repo_path" ] || continue
    shift
    printf '%s\n' "$@"
    return 0
  done < "$file"
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
