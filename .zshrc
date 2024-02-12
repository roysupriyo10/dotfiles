# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by newuser for 5.9
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /home/roysupriyo10/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/roysupriyo10/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# bun completions
[ -s "/home/roysupriyo10/.bun/_bun" ] && source "/home/roysupriyo10/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias v='nvim'
alias g='git'
alias ls='lsd -l'
alias l='lsd -al'
alias gp='git push'
alias gpl='git pull'
alias nf='neofetch'
alias gd='git diff'
alias gc='git commit'
alias gs='git status'
alias code='code-insiders'

alias sway='sway --unsupported-gpu'

# pnpm
export PNPM_HOME="/home/roysupriyo10/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export ELECTRON_OZONE_PLATFORM_HINT=auto
# pnpm end
