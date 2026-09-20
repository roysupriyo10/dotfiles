# TPM (tmux plugin manager) — lib/tmux-plugins.sh
#
# tmux.conf declares plugins with @plugin and ends with
#   run '~/.config/tmux/plugins/tpm/tpm'
# but TPM itself is not a submodule (it manages its own clones), so nothing in
# the repo puts it there. Without this hook that run line is a silent no-op and
# no plugin ever loads — the config looks wired up while tmux sits on defaults.
#
# Layout is XDG: TPM and every plugin it clones live under
# ~/.config/tmux/plugins/, which is this repo's tmux/plugins/ through the
# manifest LINK, and is gitignored there.
#
# Idempotent: clone only when missing, and install_plugins skips any plugin
# already present, so re-running install.sh is cheap and only picks up @plugin
# lines added since the last run.

TPM_REPO="https://github.com/tmux-plugins/tpm"

# Make a running server re-read tmux.conf. No-op when no server is up.
_tmux_reload_conf() {
  if tmux has-session >/dev/null 2>&1; then
    tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
  fi
}

run_hook_tmux_plugins() {
  tmux_conf="$HOME/.config/tmux/tmux.conf"
  plugin_dir="$HOME/.config/tmux/plugins"
  tpm_dir="$plugin_dir/tpm"

  if ! command -v tmux >/dev/null 2>&1; then
    log "tmux not in PATH — skipping tmux-plugins hook" >&2
    return 0
  fi

  # LINK phase runs before HOOK phase, so this should already exist; bail
  # rather than create a stray dir if the tmux manifest entry was skipped.
  if [ ! -f "$tmux_conf" ]; then
    log "$tmux_conf missing — skipping tmux-plugins hook" >&2
    return 0
  fi

  if [ -d "$tpm_dir/.git" ]; then
    log "tpm already installed"
  else
    log "installing tpm..."
    mkdir -p "$plugin_dir"
    # A leftover non-git dir would make TPM's own clones fail confusingly.
    rm -rf "$tpm_dir"
    if ! git clone --depth=1 --quiet "$TPM_REPO" "$tpm_dir"; then
      log "warning: tpm clone failed — skipping plugin install" >&2
      return 0
    fi
  fi

  if [ ! -x "$tpm_dir/bin/install_plugins" ]; then
    log "warning: $tpm_dir/bin/install_plugins missing — skipping" >&2
    return 0
  fi

  # TPM resolves the plugin dir by asking a tmux server for
  # TMUX_PLUGIN_MANAGER_PATH. A server that started before tmux.conf gained
  # that set-environment line still has it unset, and TPM then falls back to an
  # empty value and installs into "/" — which fails. Re-read the config first
  # so the server it queries reports the right path.
  _tmux_reload_conf

  log "installing tmux plugins..."
  if ! "$tpm_dir/bin/install_plugins" >/dev/null 2>&1; then
    log "warning: tpm reported errors installing plugins" >&2
  fi

  # Freshly downloaded plugins are only live once the config is read again.
  _tmux_reload_conf
}
