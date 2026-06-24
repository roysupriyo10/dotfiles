# Standalone pnpm binary install — no get.pnpm.io/install.sh, no `pnpm setup`.
# lib/tools/pnpm.sh

_pnpm_detect_platform() {
  platform=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$platform" in
    linux) printf linux ;;
    darwin) printf darwin ;;
    mingw*|msys*|cygwin*|windows*) printf win32 ;;
    *) return 1 ;;
  esac
}

_pnpm_detect_arch() {
  arch=$(uname -m | tr '[:upper:]' '[:lower:]')
  case "$arch" in
    x86_64|amd64) arch=x64 ;;
    arm64|aarch64) arch=arm64 ;;
    *) return 1 ;;
  esac
  if [ "$arch" = x64 ] && [ "$(getconf LONG_BIT 2>/dev/null || printf 64)" -eq 32 ]; then
    return 1
  fi
  printf '%s' "$arch"
}

_pnpm_is_glibc_compatible() {
  getconf GNU_LIBC_VERSION >/dev/null 2>&1 || ldd --version >/dev/null 2>&1
}

_pnpm_libc_suffix() {
  if [ "$(_pnpm_detect_platform)" = linux ] && ! _pnpm_is_glibc_compatible; then
    printf -- '-musl'
  fi
}

_pnpm_latest_version() {
  if [ -n "${PNPM_VERSION:-}" ]; then
    printf '%s' "$PNPM_VERSION"
    return 0
  fi
  json=$(curl -fsSL https://registry.npmjs.org/@pnpm/exe) || return 1
  printf '%s' "$json" | grep -o '"latest":[[:space:]]*"[0-9.]*"' | grep -o '[0-9.]*'
}

_pnpm_write_shim() {
  dest=$1
  body=$2
  printf '%s\n' "$body" >"$dest"
  chmod +x "$dest"
}

_pnpm_install_shims() {
  bin_dir=$1
  _pnpm_write_shim "$bin_dir/pn" '#!/bin/sh
exec "$(dirname "$0")/pnpm" "$@"'
  _pnpm_write_shim "$bin_dir/pnpx" '#!/bin/sh
exec "$(dirname "$0")/pnpm" dlx "$@"'
  _pnpm_write_shim "$bin_dir/pnx" '#!/bin/sh
exec "$(dirname "$0")/pnpm" dlx "$@"'
}

custom_pnpm() {
  if command -v pnpm >/dev/null 2>&1 && [ -x "$PNPM_HOME/bin/pnpm" ]; then
    return 0
  fi

  require_cmd curl "pnpm install" || return 0

  platform=$(_pnpm_detect_platform) || {
    log "warning: unsupported platform for pnpm — skipping" >&2
    return 0
  }
  arch=$(_pnpm_detect_arch) || {
    log "warning: unsupported architecture for pnpm — skipping" >&2
    return 0
  }
  libc_suffix=$(_pnpm_libc_suffix)
  version=$(_pnpm_latest_version) || {
    log "warning: could not resolve pnpm version — skipping" >&2
    return 0
  }

  major=$(printf '%s' "$version" | sed -E 's/^v//; s/^([0-9]+).*/\1/')
  if [ "$platform" = darwin ] && [ "$arch" = x64 ] && [ "$major" -ge 11 ] 2>/dev/null; then
    log "warning: pnpm v11+ has no Intel macOS binary — skipping" >&2
    return 0
  fi

  log "installing pnpm ${version}..."
  if ! (
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT INT TERM HUP
    curl -fsSL "$url" >"$tmp_dir/pnpm.tar.gz" \
      && tar -xzf "$tmp_dir/pnpm.tar.gz" -C "$tmp_dir" \
      && [ -x "$tmp_dir/pnpm" ] \
      && mkdir -p "$PNPM_HOME/bin" \
      && install -m755 "$tmp_dir/pnpm" "$PNPM_HOME/bin/pnpm"
  ); then
    log "warning: failed to install pnpm — skipping" >&2
    return 0
  fi
  _pnpm_install_shims "$PNPM_HOME/bin"

  if ! command -v pnpm >/dev/null 2>&1; then
    log "warning: pnpm not on PATH after install — skipping" >&2
    return 0
  fi
}
