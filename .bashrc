[[ $- != *i* ]] && return

export LANG=en_US.UTF-8
export EDITOR=nvim

export SCRIPTS_HOME="/Users/rs10figr/.local/bin"
export MACPORTS_PATH="/opt/local/bin:/opt/local/sbin"

case ":$PATH:" in
  *":$MACPORTS_PATH:"*) ;;
  *) export PATH="$MACPORTS_PATH:$PATH" ;;
esac

case ":$PATH:" in
  *":$SCRIPTS_HOME:"*) ;;
  *) export PATH="$SCRIPTS_HOME:$PATH" ;;
esac

# pnpm
export PNPM_HOME="/Users/rs10figr/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# go path
export GOPATH="/Users/rs10figr/go"
export PATH=$GOPATH/bin:$PATH
PROMPT_COMMAND='history -a'

alias grep='grep --color=auto'
alias cat='bat'
alias normal-ls="ls"
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
alias please='sudo'

source /usr/share/git/git-prompt.sh
source /usr/share/fzf/completion.bash
source /usr/share/fzf/key-bindings.bash
source /usr/share/git/completion/git-completion.bash

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1

export PS1='[\u \[\033[01;34m\]\W\[\033[00m\]]$(__git_ps1 " %s" | sed "s/ =//") $ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init --cmd cd bash)"
