# Shared clip helpers — source from clip-stage, agent-chat-paste, etc.
# shellcheck shell=bash

clip_git_root() {
  local root
  if root=$(git rev-parse --show-toplevel 2>/dev/null); then
    (cd "$root" && pwd)
    return 0
  fi
  root="${DOTFILES:-$HOME/dotfiles}"
  (cd "$root" && pwd)
}

clip_path_under_root() {
  local root=$1
  local name=${2:-clip.png}
  local out_dir out abs_root abs_out

  out_dir="$root/.cursor/clip"
  out="$out_dir/$name"
  mkdir -p "$out_dir"
  abs_root=$(cd "$root" && pwd)
  abs_out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
  case "$abs_out" in
    "$abs_root"/*) printf '%s' "$abs_out" ;;
    *)
      printf 'clip: refused path outside repo: %s\n' "$abs_out" >&2
      return 1
      ;;
  esac
}

# Cursor @-attach reference for a staged image (absolute path — reliable over SSH).
clip_attach_ref() {
  local abs=$1
  printf '@%s' "$abs"
}
