# rustup — lib/tools/rustup.sh

RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

have_rustup() {
  command -v rustup >/dev/null 2>&1 || [ -x "$CARGO_HOME/bin/rustup" ]
}

custom_rustup() {
  if ! have_rustup; then
    if ! command -v curl >/dev/null 2>&1; then
      log "warning: curl required to install rustup — skipping" >&2
      return 0
    fi
    log "installing rustup..."
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
      -y \
      --default-toolchain stable \
      --profile minimal; then
      log "warning: rustup install failed — skipping" >&2
      return 0
    fi
  fi

  install_env

  if ! command -v cargo >/dev/null 2>&1; then
    log "warning: cargo not available after rustup — skipping" >&2
    return 0
  fi

  rustup default stable >/dev/null 2>&1 \
    || rustup toolchain install stable --profile minimal >/dev/null 2>&1 \
    || true
}
