[[ $- != *i* ]] && return

# options
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
# snoitpo

# exports
export LANG=en_US.UTF-8
export EDITOR=nvim
export AWS_PROFILE=supriyo_admin
export CLAUDE_CODE_NO_FLICKER=1
# stropxe

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
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# mpnp

# path/tool bootstrap — before compinit on macOS
if [[ "$(uname)" == Darwin ]]; then
  if command -v /opt/homebrew/bin/brew &>/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd --shell zsh --version-file-strategy=recursive)"
  fi
fi
# potssap toorhs elbats

# completion — first init for plugins that call `compdef` (bun, etc.)
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# noitelpmoc

# bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL/bin:"*) ;;
  *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac
[ -s "$BUN_INSTALL/_bun_zsh" ] && source "$BUN_INSTALL/_bun_zsh"
# nub

# go
export GOPATH="$HOME/go"
case ":$PATH:" in
  *":$GOPATH/bin:"*) ;;
  *) export PATH="$GOPATH/bin:$PATH" ;;
esac
# og

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
alias ssh="kitten ssh"
if [[ "$(uname)" == Darwin ]]; then
  alias tsc="tsgo"
fi
# sesaila

# emacs keybinds
bindkey -e
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
# sdnibyek scame

# prompt enhancements
source "$HOME/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none
source "$HOME/dotfiles/gitstatus/gitstatus.prompt.zsh"
setopt PROMPT_SUBST
PROMPT='%B[%n %F{blue}%1~%f]${GITSTATUS_PROMPT:+ ${GITSTATUS_PROMPT}} $ %b'
if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
  RPROMPT='%F{yellow}%n@%m%f'
else
  RPROMPT=''
fi

# shell bootstrapping
source <(fzf --zsh)
if [[ "$CLAUDECODE" != "1" ]]; then
  eval "$(zoxide init --cmd cd zsh)"
fi

if [[ "$(uname)" == Linux ]] && command -v fnm &>/dev/null; then
  path=(${path:#*fnm_multishells*})
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi

if [[ "$(uname)" == Darwin ]]; then
  case ":$PATH:" in
    *":$HOME/.opencode/bin:"*) ;;
    *) export PATH="$HOME/.opencode/bin:$PATH" ;;
  esac
fi

if [[ "$(uname)" == Linux ]] && command -v /opt/homebrew/bin/brew &>/dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# gnippartstoob llehs

# re-init completion after ZLE plugins (fzf, autosuggestions, etc.)
autoload -Uz compinit && compinit -u
bindkey '^I' expand-or-complete
# noitelpmoc lanif
