# tmux-manager build — lib/tools/tmux-manager.sh

install_tm_schema() {
  schema_src="$DOTFILES/tmux-manager/schemas/config.schema.json"
  taplo_src="$DOTFILES/tmux-manager/schemas/taplo.toml"
  config_dir="${HOME}/.config/tmux-manager"
  config="${config_dir}/config.toml"
  schema_link="${config_dir}/config.schema.json"
  taplo_link="${config_dir}/taplo.toml"

  if [ ! -f "$schema_src" ]; then
    return 0
  fi

  mkdir -p "$config_dir"
  ln -sf "$schema_src" "$schema_link"
  if [ -f "$taplo_src" ]; then
    ln -sf "$taplo_src" "$taplo_link"
  fi

  # schema is generated from Rust types — refresh when sources change
  if command -v cargo >/dev/null 2>&1 && [ -d "$DOTFILES/tmux-manager" ]; then
    (
      cd "$DOTFILES/tmux-manager"
      cargo run --quiet --bin gen-schema 2>/dev/null || true
    )
  fi

  if [ ! -f "$config" ]; then
    return 0
  fi
}

install_tm_completions() {
  tm_bin="${HOME}/.local/bin/tm"

  if [ ! -x "$tm_bin" ]; then
    return 0
  fi

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

  if ! submodule_ready tmux-manager; then
    log "skipping tmux-manager — $(submodule_status_reason tmux-manager)" >&2
    return 0
  fi

  if [ ! -d "$dir" ]; then
    log "skipping tmux-manager — directory missing" >&2
    return 0
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    log "skipping tmux-manager build — cargo not available" >&2
    return 0
  fi

  if [ -x "$out" ]; then
    if ! find "$dir/src" "$dir/Cargo.toml" -type f -newer "$out" \
        -print -quit 2>/dev/null | grep -q .; then
      install_tm_completions
      install_tm_schema
      return 0
    fi
  fi

  log "building tm (tmux-manager)..."
  if ! (
    cd "$dir"
    cargo run --quiet --bin gen-schema
    cargo build --release --quiet
  ); then
    log "warning: tm build failed — skipping" >&2
    return 0
  fi

  mkdir -p "$(dirname "$install_dst")"
  rm -f "$install_dst"
  install -m755 "$out" "$install_dst"
  install_tm_completions
  install_tm_schema
}

migrate_tmux_manager_config() {
  tm_bin="${HOME}/.local/bin/tm"

  if [ ! -x "$tm_bin" ]; then
    log "tm not found at $tm_bin — build skipped or failed" >&2
    return 1
  fi

  log "migrating tmux-manager config..."
  "$tm_bin" migrate
}
