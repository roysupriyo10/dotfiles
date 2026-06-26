#!/usr/bin/env bash
# Cursor CLI status line — session token usage
set -euo pipefail

tmp=$(mktemp); timeout 0.2 cat > "$tmp" || true; payload=$(cat "$tmp"); rm -f "$tmp"; if [[ -z "$payload" ]]; then payload="{}"; fi

fmt_num() {
  local n="${1:-}"
  if [[ -z "$n" || "$n" == "null" ]]; then
    echo "—"
    return
  fi
  if (( n >= 1000000 )); then
    awk -v v="$n" 'BEGIN { printf "%.2fM", v/1000000 }'
  elif (( n >= 1000 )); then
    awk -v v="$n" 'BEGIN { printf "%.1fk", v/1000 }'
  else
    echo "$n"
  fi
}

truncate_plain() {
  local text="$1"
  local max="$2"
  if ((${#text} <= max)); then
    printf '%s' "$text"
  elif (( max <= 1 )); then
    printf '…'
  else
    printf '%s…' "${text:0:max-1}"
  fi
}

vim_prefix() {
  local colored="${1:-0}"
  local vim_mode
  vim_mode=$(echo "$payload" | jq -r '.vim.mode // empty')
  [[ -z "$vim_mode" || "$vim_mode" == "NORMAL" ]] && return

  if [[ "$colored" == 1 ]]; then
    printf '\033[90m-- %s --\033[0m ' "$vim_mode"
  else
    printf -- '-- %s -- ' "$vim_mode"
  fi
}

run_after_model() {
  local colored="${1:-0}"
  local autorun
  autorun=$(echo "$payload" | jq -r '.autorun // false')
  [[ "$autorun" != "true" ]] && return

  if [[ "$colored" == 1 ]]; then
    printf '\033[35m Run Everything\033[0m'
  else
    printf ' Run Everything'
  fi
}

width=$(echo "$payload" | jq -r '.render_width_chars // empty'); if [[ -z "$width" ]]; then width=$(tput cols < /dev/tty 2>/dev/null || echo 200); fi
model=$(echo "$payload" | jq -r '.model.display_name // "?"')
in_tok=$(echo "$payload" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$payload" | jq -r '.context_window.total_output_tokens // empty')
size=$(echo "$payload" | jq -r '.context_window.context_window_size // 0')
pct=$(echo "$payload" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
rem=$(echo "$payload" | jq -r '.context_window.remaining_percentage // empty' | cut -d. -f1)

stats_plain=$(printf 'session in %s · out %s · ctx %s%% of %s' \
  "$(fmt_num "$in_tok")" "$(fmt_num "$out_tok")" "$pct" "$(fmt_num "$size")")
if [[ -n "$rem" && "$rem" != "null" ]]; then
  stats_plain="${stats_plain} (${rem}% left)"
fi

vim_plain=$(vim_prefix 0)
run_plain=$(run_after_model 0)
prefix_len=$((${#vim_plain} + 2 + ${#model} + ${#run_plain} + 1))
max_stats=$((width - prefix_len))
(( max_stats < 1 )) && max_stats=1
stats_plain=$(truncate_plain "$stats_plain" "$max_stats")

printf '%b\033[36m[%s]\033[0m%b %s\n' \
  "$(vim_prefix 1)" "$model" "$(run_after_model 1)" "$stats_plain"

last_raw=$(echo "$payload" | jq -c '.context_window.current_usage // empty')
if [[ -n "$last_raw" && "$last_raw" != "null" && "$last_raw" != "{}" ]]; then
  parts=()
  while IFS=$'\t' read -r key val; do
    [[ "$val" == "null" ]] && continue
    label="${key//_/ }"
    parts+=("${label}=$(fmt_num "$val")")
  done < <(echo "$last_raw" | jq -r 'to_entries[] | select(.value | type == "number") | [.key, (.value | tostring)] | @tsv')
  if ((${#parts[@]} > 0)); then
    IFS=' · '
    last_plain="last call: ${parts[*]}"
    last_plain=$(truncate_plain "$last_plain" "$width")
    echo -e "\033[90m${last_plain}\033[0m"
  fi
fi
