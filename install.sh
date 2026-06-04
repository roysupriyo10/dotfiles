#!/bin/sh
# Dotfiles bootstrap — run once after cloning:
#   git clone --recursive <this-repo> ~/dotfiles && ~/dotfiles/install.sh
# Safe to re-run; idempotent.
set -e
cd "$(dirname "$0")"

# Arch/Linux: lndir is used to mirror the dotfiles tree as symlinks.
if [ "$(uname)" = "Linux" ] && ! command -v lndir >/dev/null 2>&1; then
  yay -S lndir --noconfirm
fi

# Pull in all git submodules (nvim, gitstatus, tmux-manager, zsh plugins, ...).
git submodule update --init --recursive

# tmux-manager ships no built dist/ (it's gitignored), so build it after clone
# or `tm` has nothing to run. Needs npm.
if [ -d tmux-manager ]; then
  if command -v npm >/dev/null 2>&1; then
    ( cd tmux-manager && npm install && npm run build )
  else
    echo "install.sh: npm not found — skipping tmux-manager build ('tm' won't work until built)" >&2
  fi
fi

echo "install.sh: done."
