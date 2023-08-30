# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by newuser for 5.9

# source ~/.git-prompt.sh


# PROMPT='[%n@%m%k on %B%F{cyan}%(4~|...|)%1~%F{white}]%# %b%f%k'
# PROMPT='[%B%F{cyan}%1~%F{white} $(__git_ps1 " (%s)")]%# %b%f%k'
# setopt PROMPT_SUBST ; PS1='[%F{cyan}%c%F{green}$(__git_ps1 " %s")%F{white}]\$ '

# PROMPT='%n@%m%k '


source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/roysupriyo10/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias nv=nvim
alias ls=lsd
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
