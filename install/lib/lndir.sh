have_lndir() {
  command -v lndir >/dev/null 2>&1 && return 0
  [ -x /opt/homebrew/bin/lndir ] && return 0
  return 1
}

ensure_lndir() {
  if have_lndir; then
    return 0
  fi
  pkg_install lndir
}
