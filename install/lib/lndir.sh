have_lndir() {
  command -v lndir >/dev/null 2>&1
}

ensure_lndir() {
  if have_lndir; then
    return 0
  fi
  if ! pkg_install lndir; then
    return 1
  fi
  have_lndir
}
