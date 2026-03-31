#!/bin/bash
# Shared shell config — sourced by both .zshrc and .bashrc
# OS/profile-specific fragments in .shell.d/ are auto-sourced at the end

export LANG=en_US.UTF-8
export EDITOR=nvim
export DOTFILES="$HOME/dotfiles"

# PATH additions (deduplicated)
_add_to_path() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

_add_to_path "$HOME/.local/bin"
_add_to_path "$HOME/go/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
_add_to_path "$PNPM_HOME"

# bun
export BUN_INSTALL="$HOME/.bun"
_add_to_path "$BUN_INSTALL/bin"

# fnm (Fast Node Manager)
if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi

# Aliases
alias grep='grep --color=auto'
alias cat='bat'
alias ls='lsd -l'
alias l='lsd -al'
alias v='nvim'

# Git aliases
alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit -am'
alias gp='git push'
alias gpl='git pull'

# Source all other .shell.d fragments (linux.sh, nvidia.sh, work.sh, etc.)
for _f in "$HOME/.shell.d/"*.sh; do
    [[ -f "$_f" && "$(basename "$_f")" != "common.sh" ]] && source "$_f"
done
unset _f
