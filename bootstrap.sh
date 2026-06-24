#!/bin/sh
# Bootstrap entry point.
#
# Pulls the repo FIRST, then execs the installer with the freshly-pulled code.
# This avoids the self-update lag: if install/run.sh or its lib/*.sh change,
# the new versions take effect on THIS run (run.sh sources its libs only after
# this pull has completed).
#
# bootstrap.sh itself is intentionally tiny and stable — it is the one file
# that cannot self-update in a single run, so keep changes here minimal.
set -eu

DOTFILES="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

echo "bootstrap: pulling origin master..."
git -C "$DOTFILES" pull origin master --rebase --recurse-submodules=yes

exec "$DOTFILES/install/run.sh" --no-sync "$@"
