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
[ -s "$BUN_INSTALL/_bun_zsh" ] && source "$BUN_INSTALL/_bun_zsh"
# nub
# go
export GOPATH="$HOME/go"
case ":$PATH:" in
  *":$GOPATH:"*) ;;
  *) export PATH="$GOPATH:$PATH" ;;
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
# emacs keybinds + edit-command-line on C-x C-e
bindkey -e
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
# completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# brew
if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  HOMEBREW_DIR=/opt/homebrew
fi
if [ -d "$HOMEBREW_DIR" ]; then
  # fzf — zsh has its own integration
  source <(fzf --zsh)
  # syntax highlighting + autosuggestions (load syntax-highlighting LAST)
  [ -f "$HOMEBREW_DIR/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
    source "$HOMEBREW_DIR/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [ -f "$HOMEBREW_DIR/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
    source "$HOMEBREW_DIR/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# git prompt — gitstatus (romkatv) for speed, vendored as a submodule under
# dotfiles/gitstatus.
# source "$HOME/dotfiles/gitstatus/gitstatus.plugin.zsh"
source "$HOME/dotfiles/gitstatus/gitstatus.prompt.zsh"

setopt PROMPT_SUBST
PROMPT='[%n %F{blue}%1~%f]${GITSTATUS_PROMPT:+ ${GITSTATUS_PROMPT}} $ '

export AWS_PROFILE=supriyo_admin
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
