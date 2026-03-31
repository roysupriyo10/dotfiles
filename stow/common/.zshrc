# Powerlevel10k instant prompt — must be first
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shared config
source "$HOME/.shell.d/common.sh"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
CASE_SENSITIVE="true"
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# p10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
