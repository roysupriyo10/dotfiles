#!/bin/sh
# Dotfiles bootstrap — run once after cloning:
#   git clone --recursive <this-repo> ~/dotfiles && ~/dotfiles/install.sh
# Safe to re-run; skips work that is already done.
set -e

DOTFILES="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
cd "$DOTFILES"
OS="$(uname)"

log() {
  printf 'install.sh: %s\n' "$*"
}

ensure_symlink() {
  link_src="$1"
  link_dst="$2"
  mkdir -p "$(dirname "$link_dst")"
  if [ -L "$link_dst" ] && [ "$(readlink "$link_dst")" = "$link_src" ]; then
    return 0
  fi
  ln -sf "$link_src" "$link_dst"
}

ensure_mirror() {
  mirror_src="$1"
  mirror_dst="$2"
  if [ ! -d "$mirror_src" ]; then
    return 0
  fi
  mkdir -p "$mirror_dst"
  lndir -silent "$mirror_src" "$mirror_dst" 2>/dev/null || true

  (
    cd "$mirror_src" || exit 0
    find . -type f ! -path './.git/*' -print | while IFS= read -r rel; do
      rel="${rel#./}"
      [ -n "$rel" ] || continue
      ensure_symlink "$mirror_src/$rel" "$mirror_dst/$rel"
    done
  )
}

have_lndir() {
  command -v lndir >/dev/null 2>&1 && return 0
  [ -x /opt/homebrew/bin/lndir ] && return 0
  return 1
}

ensure_lndir() {
  if have_lndir; then
    return 0
  fi

  case "$OS" in
    Linux)
      if ! command -v pacman >/dev/null 2>&1; then
        log "pacman required to install lndir on Linux" >&2
        exit 1
      fi
      log "installing lndir (pacman)..."
      sudo pacman -S --needed --noconfirm lndir
      ;;
    Darwin)
      if sudo -Hu homebrew brew list lndir >/dev/null 2>&1; then
        return 0
      fi
      log "installing lndir (homebrew)..."
      sudo -Hu homebrew brew install lndir
      ;;
    *)
      log "unsupported OS for lndir install: $OS" >&2
      exit 1
      ;;
  esac
}

ensure_submodules() {
  if git submodule status --recursive 2>/dev/null | grep -qE '^[-+]'; then
    log "initializing submodules..."
    git submodule update --init --recursive
  fi
}

ensure_tmux_manager() {
  dir="$DOTFILES/tmux-manager"
  out="$dir/dist/index.js"

  if [ ! -d "$dir" ]; then
    return 0
  fi
  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found — skipping tmux-manager build" >&2
    return 0
  fi

  if [ -f "$out" ] && [ -d "$dir/node_modules" ]; then
    if ! find "$dir/src" "$dir/package.json" "$dir/tsconfig.json" \
        -type f -newer "$out" -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  fi

  log "building tmux-manager..."
  (
    cd "$dir"
    npm install --prefer-offline --no-audit --no-fund --silent
    npm run build --silent
  )
}

ensure_submodules
ensure_lndir

if ! have_lndir; then
  log "lndir not available after install" >&2
  exit 1
fi

ensure_symlink "$DOTFILES/.zshrc" "$HOME/.zshrc"
ensure_symlink "$DOTFILES/.bashrc" "$HOME/.bashrc"
if [ "$OS" = Linux ]; then
  ensure_symlink "$DOTFILES/.zprofile" "$HOME/.zprofile"
fi

ensure_mirror "$DOTFILES/kitty" "$HOME/.config/kitty"
ensure_mirror "$DOTFILES/lsd" "$HOME/.config/lsd"
ensure_mirror "$DOTFILES/tmux" "$HOME/.config/tmux"
ensure_mirror "$DOTFILES/nvim" "$HOME/.config/nvim"
ensure_mirror "$DOTFILES/.local/bin" "$HOME/.local/bin"

sh "$DOTFILES/.cursor/install.sh"

case "$OS" in
  Linux)
    ensure_mirror "$DOTFILES/sway" "$HOME/.config/sway"
    ensure_mirror "$DOTFILES/mako" "$HOME/.config/mako"
    ensure_mirror "$DOTFILES/fontconfig" "$HOME/.config/fontconfig"
    ensure_mirror "$DOTFILES/environment.d" "$HOME/.config/environment.d"
    ensure_mirror "$DOTFILES/wireplumber" "$HOME/.config/wireplumber"
    ensure_mirror "$DOTFILES/foot" "$HOME/.config/foot"
    ensure_mirror "$DOTFILES/imv" "$HOME/.config/imv"
    ensure_mirror "$DOTFILES/systemd/user" "$HOME/.config/systemd/user"
    ensure_tmux_manager
    ;;
  Darwin)
    ensure_mirror "$DOTFILES/aerospace" "$HOME/.config/aerospace"
    ;;
esac

log "done."
