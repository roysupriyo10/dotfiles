# Sync dotfiles repo before bootstrap (set -e propagates failures).

sync_dotfiles() {
  log "pulling origin master..."
  git -C "$DOTFILES" pull origin master --rebase --recurse-submodules=yes
}
