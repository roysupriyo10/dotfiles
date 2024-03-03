[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

export LANG=en_US.UTF-8
export EDITOR=nvim

export QHOME="/home/roysupriyo10/.local/share/q/l64"
case ":$PATH:" in
  *":$QHOME:"*) ;;
  *) export PATH="$QHOME:$PATH" ;;
esac

export SCRIPTS_HOME="/home/roysupriyo10/.local/bin"
# export PATH="$SCRIPTS_HOME:$PATH"
case ":$PATH:" in
  *":$SCRIPTS_HOME:"*) ;;
  *) export PATH="$SCRIPTS_HOME:$PATH" ;;
esac

# pnpm
export PNPM_HOME="/home/roysupriyo10/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

alias ls="lsd -l"
alias v="nvim"
alias vim="nvim"
alias gd="git diff --oneline"
alias gs="git status"
alias gpl="git pull"
alias gp="git push"
alias g="git"
alias ga="git add"
alias gc="git commit -am"
alias blesh="source ~/.local/share/blesh/ble.sh"

source /usr/share/git/git-prompt.sh
source /usr/share/fzf/completion.bash
source /usr/share/fzf/key-bindings.bash

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1
export PS1='[\u \[\033[01;34m\]\W\[\033[00m\]]$(__git_ps1 " %s" | sed "s/ =//") $ '
# export PS1='[\u \[\033[01;34m\]\W\[\033[00m\]]$(__git_ps1 " %s") $ '

eval "$(zoxide init --cmd cd bash)"
#
# bind 'set show-all-if-ambiguous on'
# bind 'TAB:menu-complete'
