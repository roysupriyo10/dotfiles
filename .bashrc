[[ $- != *i* ]] && return

# if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
#   exec sway
# fi

export LANG=en_US.UTF-8
export EDITOR=nvim

# export QHOME="/home/roysupriyo10figr/.local/share/q/l64"
# case ":$PATH:" in
#   *":$QHOME:"*) ;;
#   *) export PATH="$QHOME:$PATH" ;;
# esac

export SCRIPTS_HOME="/home/roysupriyo10figr/.local/bin"
# export PATH="$SCRIPTS_HOME:$PATH"
case ":$PATH:" in
  *":$SCRIPTS_HOME:"*) ;;
  *) export PATH="$SCRIPTS_HOME:$PATH" ;;
esac

# pnpm
export PNPM_HOME="/home/roysupriyo10figr/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# go path
export GOPATH="/home/roysupriyo10figr/go"
export PATH=$GOPATH/bin:$PATH
PROMPT_COMMAND='history -a'

alias grep='grep --color=auto'
alias cat='bat'
alias ls="lsd -l"
alias l="lsd -al"
alias v="nvim"
alias default-vim="/usr/bin/vim"
alias vim="nvim"
alias gd="git diff"
alias gs="git status"
alias gpl="git pull"
alias gp="git push"
alias g="git"
alias ga="git add"
alias gc="git commit -am"
alias gfo="git fetch origin"
alias gplo="git pull origin"
alias blesh="source ~/.local/share/blesh/ble.sh"
alias bitch='sudo $(history -p !!)'
alias please='sudo'
alias 'cover-letter'='cat ~/misc/cover-letter.pdf | wl-copy'
alias code='code-insiders'

# electron extra flags
alias mongodb-comp="mongodb-compass --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --ignore-additional-command-line-flags"


source /usr/share/git/git-prompt.sh
source /usr/share/fzf/completion.bash
source /usr/share/fzf/key-bindings.bash
source /usr/share/git/completion/git-completion.bash

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1
export PS1='[\u \[\033[01;34m\]\W\[\033[00m\]]$(__git_ps1 " %s" | sed "s/ =//") $ '

# atac config
export ATAC_MAIN_DIR=/home/roysupriyo10figr/developer/atac-files
export ATAC_KEY_BINDINGS=$ATAC_MAIN_DIR/vim-bindings.toml

# export PS1='[\u \[\033[01;34m\]\W\[\033[00m\]]$(__git_ps1 " %s") $ '

eval "$(zoxide init --cmd cd bash)"
#
# bind 'set show-all-if-ambiguous on'
# bind 'TAB:menu-complete'
