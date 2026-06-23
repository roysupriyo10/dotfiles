# CUSTOM toolchain handlers: fnm (+ node), pnpm, rustup, tmux-manager.

RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

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

rustup_env() {
  if [ -f "$CARGO_HOME/env" ]; then
    # shellcheck disable=SC1090
    . "$CARGO_HOME/env"
  fi
}

have_rustup() {
  command -v rustup >/dev/null 2>&1 || [ -x "$CARGO_HOME/bin/rustup" ]
}

custom_rustup() {
  if ! have_rustup; then
    if ! command -v curl >/dev/null 2>&1; then
      log "curl required to install rustup" >&2
      return 1
    fi
    log "installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
      -y \
      --default-toolchain stable \
      --profile minimal
  fi

  rustup_env

  if ! command -v cargo >/dev/null 2>&1; then
    log "cargo not available after rustup install" >&2
    return 1
  fi

  rustup default stable >/dev/null 2>&1 || rustup toolchain install stable --profile minimal
}

install_tm_completions() {
  tm_bin="${HOME}/.local/bin/tm"

  if [ ! -x "$tm_bin" ]; then
    return 0
  fi

  # remove stale static completions (replaced by dynamic COMPLETE=* sourcing in shell rc)
  rm -f "${HOME}/.local/share/zsh/site-functions/_tm"
  rm -f "${HOME}/.local/share/bash-completion/completions/tm"

  fish_dir="${HOME}/.config/fish/completions"
  mkdir -p "$fish_dir"
  printf 'COMPLETE=fish %s | source\n' "$tm_bin" >"$fish_dir/tm.fish"
}

custom_tmux_manager() {
  dir="$DOTFILES/tmux-manager"
  out="$dir/target/release/tm"
  install_dst="${HOME}/.local/bin/tm"

  if [ ! -d "$dir" ]; then
    return 0
  fi

  rustup_env

  if ! command -v cargo >/dev/null 2>&1; then
    log "cargo not found — run install with rustup in toolchain first" >&2
    return 1
  fi

  if [ -x "$out" ]; then
    if ! find "$dir/src" "$dir/Cargo.toml" -type f -newer "$out" \
        -print -quit 2>/dev/null | grep -q .; then
      install_tm_completions
      return 0
    fi
  fi

  log "building tm (tmux-manager)..."
  (
    cd "$dir"
    cargo build --release --quiet
  )

  mkdir -p "$(dirname "$install_dst")"
  rm -f "$install_dst"
  install -m755 "$out" "$install_dst"
  install_tm_completions
}

migrate_tmux_manager_config() {
  tm_bin="${HOME}/.local/bin/tm"

  if [ ! -x "$tm_bin" ]; then
    log "tm not found at $tm_bin — build first (install/run.sh)" >&2
    return 1
  fi

  log "migrating tmux-manager config..."
  "$tm_bin" migrate
}

run_custom_tool() {
  case "$1" in
    fnm) custom_fnm ;;
    pnpm) custom_pnpm ;;
    rustup) custom_rustup ;;
    tmux-manager) custom_tmux_manager ;;
    *)
      log "unknown custom tool: $1" >&2
      return 1
      ;;
  esac
}
