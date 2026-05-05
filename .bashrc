[[ $- != *i* ]] && return

# options
shopt -s cmdhist

shopt -s lithist

HISTTIMEFORMAT="%F %T "
# snoitpo

export LANG=en_US.UTF-8
export EDITOR=nvim

# personal scripts
export SCRIPTS_HOME="$HOME/.local/bin"
case ":$PATH:" in
  *":$SCRIPTS_HOME:"*) ;;
  *) export PATH="$SCRIPTS_HOME:$PATH" ;;
esac
# stpircs lanosrep

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# mpnp

# bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL:"*) ;;
  *) export PATH="$BUN_INSTALL:$PATH" ;;
esac
[ -s "$BUN_INSTALL/_bun_bash" ] && source "$BUN_INSTALL/_bun_bash"
# nub

# go
export GOPATH="$HOME/go"
case ":$PATH:" in
  *":$GOPATH:"*) ;;
  *) export PATH="$GOPATH:$PATH" ;;
esac
# og

PROMPT_COMMAND='history -a'

# aliases
alias grep='grep --color=auto'
alias cat='bat'
alias ls='lsd'
alias v="nvim"
alias gd="git diff"
alias gs="git status"
alias g="git"
alias ga="git add"
alias gfo="git fetch origin"


# macos defaults
if [ -f "/System/Volumes/Data/Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash" ]; then
  source /System/Volumes/Data/Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
fi
if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  HOMEBREW_DIR=/opt/homebrew # hardcoded to prevent sudo slowdown , since our brew user is system wide user accessed using sudo -H
fi
if [ -d "$HOMEBREW_DIR" ]; then
  if [ -f "$HOMEBREW_DIR/opt/fzf/shell/completion.bash" ]; then
    source "$HOMEBREW_DIR/opt/fzf/shell/completion.bash"
  fi
  if [ -f "$HOMEBREW_DIR/opt/fzf/shell/key-bindings.bash" ]; then
    source "$HOMEBREW_DIR/opt/fzf/shell/key-bindings.bash"
  fi
fi

# arch based completions
if [ -f "/usr/share/fzf/completion.bash" ]; then
  source /usr/share/fzf/completion.bash
fi
if [ -f "/usr/share/fzf/key-bindings.bash" ]; then
  source /usr/share/fzf/key-bindings.bash
fi
if [ -f "/usr/share/git/completion/git-completion.bash" ]; then
  source /usr/share/git/completion/git-completion.bash
fi

source "$HOME/dotfiles/gitstatus/gitstatus.prompt.sh"

PS1='\[\e[1m\][\u \[\e[34m\]\W\[\e[39m\]]${GITSTATUS_PROMPT:+ ${GITSTATUS_PROMPT}}\[\e[1m\] $ \[\e[0m\]'

export AWS_PROFILE=supriyo_admin

if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd bash)"
fi

eval "$(fnm env --use-on-cd --shell bash)"

eval "$(/opt/homebrew/bin/brew shellenv)"
