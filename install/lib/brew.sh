# Shared Homebrew invocation — used by install scripts and shell rc.
# Expects OS when deciding sudo -Hu homebrew vs direct brew.

brew_run() {
  if [ "$(uname)" != Darwin ]; then
    command brew "$@"
    return $?
  fi
  if id homebrew >/dev/null 2>&1; then
    sudo -Hu homebrew command brew "$@"
  else
    command brew "$@"
  fi
}

brew_prefix() {
  if [ -x /opt/homebrew/bin/brew ]; then
    /opt/homebrew/bin/brew --prefix
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    brew_run --prefix
    return 0
  fi
  return 1
}

brew_shellenv() {
  if [ -x /opt/homebrew/bin/brew ]; then
    # shellcheck disable=SC2046
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi
  prefix=$(brew_prefix 2>/dev/null) || return 1
  # shellcheck disable=SC2046
  eval "$(brew_run shellenv)"
}
