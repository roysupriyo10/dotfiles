# Login-shell only (.zshrc does not run on VT1 when Sway replaces this shell via exec).
#
# Put tmux attach, prompt, plugins, fzf, etc. in .zshrc.
# Session-wide env: ~/.config/environment.d/ (see dotfiles/environment.d/)

# --- shared login init (runs on every login path) ---------------------------

# --- graphical autostart (must stay last) -----------------------------------
# tty2+ and SSH skip this; only local VT1 for rs10 starts Sway.
if [[ "$USER" == rs10 \
      && -z "${WAYLAND_DISPLAY:-}" \
      && -z "${DISPLAY:-}" \
      && -z "${SSH_CONNECTION:-}" \
      && -n "${XDG_VTNR:-}" \
      && "$XDG_VTNR" -eq 1 ]] \
      && command -v sway >/dev/null; then
  exec sway
fi


# Added by Antigravity CLI installer
export PATH="/home/rs10/.local/bin:$PATH"
