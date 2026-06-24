[[ $- != *i* ]] && return

# options
shopt -s cmdhist

shopt -s lithist

HISTTIMEFORMAT="%F %T "
# snoitpo

export LANG=en_US.UTF-8
export EDITOR=nvim

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# shared libs — brew before env
. "$DOTFILES/install/lib/brew.sh"
. "$DOTFILES/install/lib/env.sh"
install_env

# pnpm/rust/scripts/gopath — install_env
# mpnp / tsur / stpircs lanosrep

# tm completions (dynamic — subcommands + config names)
if command -v tm >/dev/null 2>&1; then
  source <(COMPLETE=bash tm 2>/dev/null)
fi

# bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL:"*) ;;
  *) export PATH="$BUN_INSTALL:$PATH" ;;
esac
[ -s "$BUN_INSTALL/_bun_bash" ] && source "$BUN_INSTALL/_bun_bash"
# nub

# go — GOPATH/bin handled by install_env
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
  eval "$(/opt/homebrew/bin/brew shellenv)"
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

[ -f "$DOTFILES/gitstatus/gitstatus.prompt.sh" ] \
  && source "$DOTFILES/gitstatus/gitstatus.prompt.sh"

PS1='\[\e[1m\][\u \[\e[34m\]\W\[\e[39m\]]${GITSTATUS_PROMPT:+ ${GITSTATUS_PROMPT}}\[\e[1m\] $ \[\e[0m\]'

export AWS_PROFILE=supriyo_admin

if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd bash)"
fi

if command -v fnm &>/dev/null; then
  PATH="$(printf '%s\n' "${PATH//:/$'\n'}" | grep -v 'fnm_multishells' | paste -sd: -)"
  eval "$(fnm env --use-on-cd --shell bash)"
fi

