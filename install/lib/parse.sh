# Shared config line parsing for manifest, toolchain, submodule-deps.

trim_line() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

strip_comment() {
  printf '%s' "${1%%#*}"
}

# each_config_line <file> <callback> — callback receives one trimmed, non-empty line.
each_config_line() {
  file=$1
  callback=$2
  [ -f "$file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line=$(strip_comment "$line")
    line=$(trim_line "$line")
    [ -z "$line" ] && continue
    "$callback" "$line"
  done < "$file"
}
