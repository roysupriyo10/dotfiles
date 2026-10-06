# Generic package install through whichever manager this host has: yay/pacman,
# dnf or homebrew. Per-manager package names live in install/packages.
# Requires brew.sh to be sourced first.

# pkg_name <pkg> <brew|dnf> — what <pkg> is called under that manager; prints
# nothing when the manager does not ship it (see install/packages).
pkg_name() {
  table="${INSTALL_DIR:-}/packages"
  if [ ! -f "$table" ]; then
    [ "$2" != brew ] || printf '%s\n' "$1"
    return 0
  fi
  awk -v pkg="$1" -v mgr="$2" '
    /^[[:space:]]*(#|$)/ { next }
    $1 == pkg {
      name = (mgr == "brew") ? $2 : $3
      if (name != "" && name != "-") print name
      listed = 1
      exit
    }
    END { if (!listed && mgr == "brew") print pkg }
  ' "$table"
}

# pkg_available <pkg> — can any package manager on this host provide it?
pkg_available() {
  case "$OS" in
    Linux)
      if command -v yay >/dev/null 2>&1 || command -v pacman >/dev/null 2>&1; then
        return 0
      fi
      if command -v dnf >/dev/null 2>&1 && [ -n "$(pkg_name "$1" dnf)" ]; then
        return 0
      fi
      command -v brew >/dev/null 2>&1 && [ -n "$(pkg_name "$1" brew)" ]
      ;;
    Darwin) [ -n "$(pkg_name "$1" brew)" ] ;;
    *) return 1 ;;
  esac
}

pkg_yay() {
  pkg="$1"
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  if command -v yay >/dev/null 2>&1; then
    log "installing $pkg (yay)..."
    yay -S --needed --noconfirm "$pkg"
    return $?
  fi
  if command -v pacman >/dev/null 2>&1; then
    log "installing $pkg (pacman)..."
    sudo pacman -S --needed --noconfirm "$pkg"
    return $?
  fi
  return 1
}

pkg_dnf() {
  pkg="$1"
  command -v dnf >/dev/null 2>&1 || return 1
  if rpm -q "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  log "installing $pkg (dnf)..."
  sudo dnf install -y "$pkg"
}

pkg_brew() {
  pkg="$1"
  if brew_run list "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  log "installing $pkg (homebrew)..."
  brew_run install "$pkg"
}

# pkg_install <pkg> [brew-pkg]
#   pkg      — yay/pacman package, and the key into install/packages
#   brew-pkg — homebrew formula, overriding install/packages
pkg_install() {
  linux_pkg="$1"
  brew_pkg="${2:-$(pkg_name "$1" brew)}"
  case "$OS" in
    Linux)
      if pkg_yay "$linux_pkg"; then
        return 0
      fi
      dnf_pkg=$(pkg_name "$linux_pkg" dnf)
      if [ -n "$dnf_pkg" ] && pkg_dnf "$dnf_pkg"; then
        return 0
      fi
      if [ -n "$brew_pkg" ] && command -v brew >/dev/null 2>&1; then
        pkg_brew "$brew_pkg"
        return $?
      fi
      log "no package manager on this host provides $linux_pkg (yay, pacman, dnf, brew)" >&2
      return 1
      ;;
    Darwin)
      if [ -z "$brew_pkg" ]; then
        log "$linux_pkg has no homebrew formula" >&2
        return 1
      fi
      pkg_brew "$brew_pkg"
      ;;
    *)
      log "unsupported OS for package install: $OS" >&2
      return 1
      ;;
  esac
}
