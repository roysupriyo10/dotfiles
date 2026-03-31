# Exit if not interactive
[[ $- != *i* ]] && return

# Shared config
source "$HOME/.shell.d/common.sh"

# Bash-specific completions
[[ -f /usr/share/git/git-prompt.sh ]] && source /usr/share/git/git-prompt.sh
[[ -f /usr/share/fzf/completion.bash ]] && source /usr/share/fzf/completion.bash
[[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
[[ -f /usr/share/git/completion/git-completion.bash ]] && source /usr/share/git/completion/git-completion.bash

# Git prompt
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"
export GIT_PS1_SHOWCOLORHINTS=1
export PS1='[\u \[\033[01;34m\]\W\[\033[00m\]]$(__git_ps1 " %s" | sed "s/ =//") $ '

# zoxide
eval "$(zoxide init --cmd cd bash)"

