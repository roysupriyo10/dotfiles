have_lndir() {
  command -v lndir >/dev/null 2>&1
}

ensure_lndir() {
  install_env
  if have_lndir; then
    return 0
  fi
  if ! pkg_install lndir; then
    return 1
  fi
  install_env
  have_lndir
}
