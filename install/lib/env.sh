# POSIX PATH / tool bootstrap shared by install and shell rc.
# Requires brew.sh to be sourced first (install/run.sh and shell rc).

path_prepend() {
  dir=$1
  [ -n "$dir" ] || return 0
  case ":$PATH:" in
    *":$dir:"*) ;;
    *) PATH="$dir:$PATH"; export PATH ;;
  esac
}

install_env() {
  SCRIPTS_HOME="${SCRIPTS_HOME:-$HOME/.local/bin}"
  path_prepend "$SCRIPTS_HOME"

  PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
  export PNPM_HOME
  path_prepend "$PNPM_HOME/bin"

  CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
  export CARGO_HOME
  if [ -f "$CARGO_HOME/env" ]; then
    # shellcheck disable=SC1090
    . "$CARGO_HOME/env"
  fi

  GOPATH="${GOPATH:-$HOME/go}"
  export GOPATH
  path_prepend "$GOPATH/bin"

  if [ "$(uname)" = Darwin ]; then
    brew_shellenv 2>/dev/null || true
  fi

  FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
  export FNM_DIR
  path_prepend "$FNM_DIR"
  if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash 2>/dev/null)" || true
  fi
}
