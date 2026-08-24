# Generic package install: yay (Linux) / homebrew (macOS).
# Requires brew.sh to be sourced first.

pkg_yay() {
  pkg="$1"
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  if command -v yay >/dev/null 2>&1; then
    log "installing $pkg (yay)..."
    yay -S --needed --noconfirm "$pkg"
    return 0
  fi
  if command -v pacman >/dev/null 2>&1; then
    log "installing $pkg (pacman)..."
    sudo pacman -S --needed --noconfirm "$pkg"
    return 0
  fi
  return 1
}

pkg_brew() {
  pkg="$1"
  if brew_run list "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  log "installing $pkg (homebrew)..."
  brew_run install "$pkg"
}

# pkg_install <linux-pkg> [brew-pkg]
pkg_install() {
  linux_pkg="$1"
  brew_pkg="${2:-$1}"
  case "$OS" in
    Linux)
      if pkg_yay "$linux_pkg"; then
        return 0
      fi
      if command -v brew >/dev/null 2>&1; then
        pkg_brew "$brew_pkg"
        return $?
      fi
      log "yay, pacman or brew required to install $linux_pkg" >&2
      return 1
      ;;
    Darwin) pkg_brew "$brew_pkg" ;;
    *)
      log "unsupported OS for package install: $OS" >&2
      return 1
      ;;
  esac
}
