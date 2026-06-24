# Shared clip helpers — source from clip-stage, agent-chat-paste, cursor-clip-paste.
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

clip_attach_ref() {
  local abs=$1
  printf '@%s' "$abs"
}

clip_debug() {
  [ "${CLIP_DEBUG:-}" = 1 ] || return 0
  printf 'clip: %s\n' "$*" >&2
}

# Stage local kitty clipboard → file under git root.
clip_stage_local() {
  local root out
  command -v kitten >/dev/null 2>&1 || {
    printf 'clip: kitten not found\n' >&2
    return 1
  }
  root=$(clip_git_root)
  out=$(clip_path_under_root "$root" "${1:-clip.png}")
  kitten clipboard -g "$out"
  printf '%s' "$out"
}

# Inject text into the focused kitty window (agent prompt or shell).
clip_inject_text() {
  local text=$1
  command -v kitten >/dev/null 2>&1 || return 1
  if [ -n "${KITTY_WINDOW_ID:-}" ]; then
    printf '%s' "$text" | kitten @ send-text --match self --stdin
  else
    printf '%s' "$text" | kitten @ send-text --match active-window --stdin
  fi
}

# Parse kitten @ ls JSON for the focused window (cwd, cmdline, ssh target).
clip_active_window_info() {
  command -v kitten python3 >/dev/null 2>&1 || return 1
  kitten @ ls --match active-window --all-env-vars 2>/dev/null | python3 - <<'PY'
import json, os, re, sys

raw = sys.stdin.read().strip()
if not raw:
    sys.exit(1)

def iter_windows(node):
    if isinstance(node, dict):
        if "windows" in node:
            for w in node["windows"]:
                yield w
        for v in node.values():
            yield from iter_windows(v)
    elif isinstance(node, list):
        for item in node:
            yield from iter_windows(item)

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(1)

windows = list(iter_windows(data))
if not windows:
    sys.exit(1)

def focused(w):
    return w.get("is_focused") or w.get("is_active")

win = next((w for w in windows if focused(w)), windows[0])
cmd = win.get("cmdline", "")
if isinstance(cmd, list):
    cmd = " ".join(cmd)
elif not isinstance(cmd, str):
    cmd = str(cmd)

env = win.get("env", {}) or {}
blob = cmd + json.dumps(env)
ssh = bool(re.search(r"SSH_CONNECTION|SSH_CLIENT|SSH_TTY", blob))
if not ssh and re.search(r"\bssh\b|kitten ssh", cmd, re.I):
    ssh = 1

target = ""
m = re.search(r"([\w.-]+@[\w.-]+)", cmd)
if m:
    target = m.group(1)
else:
    host = env.get("SSH_CONNECTION", "").split()[0]
    user = os.environ.get("USER", "rs10")
    if host:
        target = f"{user}@{host}"

cwd = win.get("cwd", "") or ""
print(f"ssh={int(bool(ssh))}")
print(f"target={target}")
print(f"cwd={cwd}")
PY
}

clip_remote_repo_root() {
  local info cwd dotfiles
  dotfiles="${DOTFILES:-$HOME/dotfiles}"
  info=$(clip_active_window_info) || {
    printf '%s' "$dotfiles"
    return 0
  }
  cwd=$(printf '%s\n' "$info" | sed -n 's/^cwd=//p')
  if [ -n "$cwd" ] && { [ "$cwd" = "$dotfiles" ] || [[ "$cwd" == */dotfiles ]]; }; then
    printf '%s' "$cwd"
    return 0
  fi
  printf '%s' "$dotfiles"
}

clip_push_to_ssh_target() {
  local local_path=$1 remote_path=$2
  local info target remote_dir

  info=$(clip_active_window_info) || return 1
  target=$(printf '%s\n' "$info" | sed -n 's/^target=//p')
  [ -n "$target" ] || return 1

  remote_dir=$(dirname "$remote_path")
  clip_debug "scp → $target:$remote_path"
  ssh "$target" "mkdir -p '$remote_dir'"
  scp "$local_path" "$target:$remote_path"
}
