# CUSTOM toolchain handlers: fnm (+ node), pnpm, tmux-manager.

fnm_env() {
  if [ "$OS" = Darwin ] && [ -d /opt/homebrew/bin ]; then
    PATH="/opt/homebrew/bin:$PATH"
    export PATH
  fi
  if [ -x "$FNM_DIR/fnm" ]; then
    PATH="$FNM_DIR:$PATH"
    export PATH
  fi
  if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
  fi
}

have_fnm() {
  if [ "$OS" = Darwin ] && [ -x /opt/homebrew/bin/fnm ]; then
    return 0
  fi
  if [ -x "$FNM_DIR/fnm" ]; then
    return 0
  fi
  command -v fnm >/dev/null 2>&1
}

custom_fnm() {
  if ! have_fnm; then
    case "$OS" in
      Linux)
        if ! command -v curl >/dev/null 2>&1; then
          log "curl required to install fnm" >&2
          return 1
        fi
        log "installing fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash -s -- \
          --install-dir "$FNM_DIR" \
          --skip-shell
        ;;
      Darwin)
        pkg_install fnm
        ;;
      *)
        log "unsupported OS for fnm: $OS" >&2
        return 1
        ;;
    esac
  fi

  fnm_env
  if ! command -v fnm >/dev/null 2>&1; then
    log "fnm not available after install" >&2
    return 1
  fi

  if fnm list 2>/dev/null | grep -qE '\blatest\b'; then
    fnm install --latest >/dev/null 2>&1 || fnm install --latest
    fnm default latest >/dev/null 2>&1 || fnm default latest
  else
    log "installing latest node (npm included)..."
    fnm install --latest
    fnm default latest 2>/dev/null || {
      ver=$(fnm list 2>/dev/null | sed -n 's/^[ *]*\(v[0-9][0-9.]*\).*/\1/p' | sort -V | tail -1)
      [ -n "$ver" ] && fnm default "$ver"
    }
  fi
  fnm_env
}

custom_pnpm() {
  fnm_env
  export PNPM_HOME
  PATH="$PNPM_HOME/bin:$PATH"
  export PATH

  if command -v pnpm >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log "curl required to install pnpm" >&2
    return 1
  fi

  log "installing pnpm..."
  curl -fsSL https://get.pnpm.io/install.sh | env PNPM_HOME="$PNPM_HOME" sh -
}

custom_tmux_manager() {
  dir="$DOTFILES/tmux-manager"
  out="$dir/dist/index.js"

  if [ ! -d "$dir" ]; then
    return 0
  fi

  fnm_env
  export PNPM_HOME
  PATH="$PNPM_HOME/bin:$PATH"
  export PATH

  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found — skipping tmux-manager build" >&2
    return 0
  fi

  if [ -f "$out" ] && [ -d "$dir/node_modules" ]; then
    if ! find "$dir/src" "$dir/package.json" "$dir/tsconfig.json" \
        -type f -newer "$out" -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  fi

  log "building tmux-manager..."
  (
    cd "$dir"
    npm install --prefer-offline --no-audit --no-fund --silent
    npm run build --silent
  )
}

run_custom_tool() {
  case "$1" in
    fnm) custom_fnm ;;
    pnpm) custom_pnpm ;;
    tmux-manager) custom_tmux_manager ;;
    *)
      log "unknown custom tool: $1" >&2
      return 1
      ;;
  esac
}
