# fnm (+ node) — lib/tools/fnm.sh

custom_fnm() {
  if ! have_fnm; then
    case "$OS" in
      Linux)
        require_cmd curl "fnm install" || return 0
        log "installing fnm..."
        if ! curl -fsSL https://fnm.vercel.app/install | bash -s -- \
          --install-dir "$FNM_DIR" \
          --skip-shell; then
          log "warning: fnm install failed — skipping" >&2
          return 0
        fi
        ;;
      Darwin)
        if ! pkg_install fnm; then
          log "warning: fnm install failed — skipping" >&2
          return 0
        fi
        ;;
      *)
        log "warning: unsupported OS for fnm: $OS — skipping" >&2
        return 0
        ;;
    esac
  fi

  if ! command -v fnm >/dev/null 2>&1; then
    log "warning: fnm not available after install — skipping node setup" >&2
    return 0
  fi

  if fnm list 2>/dev/null | grep -qE '\blatest\b'; then
    fnm install --latest >/dev/null 2>&1 || fnm install --latest || true
    fnm default latest >/dev/null 2>&1 || fnm default latest || true
  else
    log "installing latest node..."
    fnm install --latest || {
      log "warning: fnm install --latest failed — skipping" >&2
      return 0
    }
    fnm default latest 2>/dev/null || {
      ver=$(fnm list 2>/dev/null | sed -n 's/^[ *]*\(v[0-9][0-9.]*\).*/\1/p' | sort -V | tail -1)
      [ -n "$ver" ] && fnm default "$ver"
    }
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
