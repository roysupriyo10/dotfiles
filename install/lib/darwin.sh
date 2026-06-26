# macOS LaunchAgents and login-time setup.

_darwin_install_launchagent() {
  label=$1
  plist_src=$2
  plist_dst="$HOME/Library/LaunchAgents/${label}.plist"

  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s|@HOME@|$HOME|g" "$plist_src" > "${plist_dst}.tmp"
  if [ -f "$plist_dst" ] && cmp -s "${plist_dst}.tmp" "$plist_dst"; then
    rm -f "${plist_dst}.tmp"
  else
    mv "${plist_dst}.tmp" "$plist_dst"
  fi

  uid=$(id -u)
  domain="gui/$uid"
  launchctl bootout "$domain/$label" 2>/dev/null || true
  if launchctl bootstrap "$domain" "$plist_dst" 2>/dev/null; then
    launchctl enable "$domain/$label" 2>/dev/null || true
  else
    launchctl load -w "$plist_dst" 2>/dev/null || true
  fi
  launchctl kickstart -k "$domain/$label" 2>/dev/null || true
}

run_hook_darwin_keymap() {
  [ "$OS" = Darwin ] || return 0

  script_repo="$DOTFILES/.local/bin/hidutil-keymap"
  script_live="$HOME/.local/bin/hidutil-keymap"
  plist_src="$DOTFILES/darwin/launchagents/com.local.hidutil-keymap.plist"

  [ -f "$script_repo" ] || {
    log "warning: hidutil-keymap script missing, skipping" >&2
    return 0
  }
  [ -f "$plist_src" ] || {
    log "warning: hidutil-keymap LaunchAgent missing, skipping" >&2
    return 0
  }

  chmod +x "$script_repo"

  if [ ! -x "$script_live" ]; then
    log "warning: $script_live not present — run install manifest sync first" >&2
    return 0
  fi

  _darwin_install_launchagent com.local.hidutil-keymap "$plist_src"

  if ! "$script_live"; then
    log "warning: hidutil-keymap failed — grant Input Monitoring to hidutil in System Settings if keys do not remap at login" >&2
  fi
}
