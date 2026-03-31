#!/bin/bash
set -euo pipefail

# ==============================================================================
# bootstrap.sh — Fully bootstrappable dotfiles installer
#
# Works on a completely fresh machine (Arch Linux or macOS).
# Idempotent: safe to run multiple times.
#
# Multi-user: checks machines/<hostname>.<username>.sh first, then
# falls back to machines/<hostname>.sh. Ansible runs once per machine
# (system-level); stow runs per-user (user-level).
#
# Usage:
#   ./bootstrap.sh                 # full bootstrap
#   ./bootstrap.sh --stow-only     # re-deploy stow packages only
#   ./bootstrap.sh --ansible-only  # re-run ansible only
#   ./bootstrap.sh --ansible-tags "gui,nvidia"  # run specific ansible tags
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

info()  { echo "==> $*"; }
warn()  { echo "==> [WARN] $*"; }
error() { echo "==> [ERROR] $*" >&2; exit 1; }

command_exists() { command -v "$1" &>/dev/null; }

# ------------------------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------------------------

STOW_ONLY=false
ANSIBLE_ONLY=false
ANSIBLE_TAGS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stow-only)    STOW_ONLY=true; shift ;;
        --ansible-only) ANSIBLE_ONLY=true; shift ;;
        --ansible-tags) ANSIBLE_TAGS="$2"; shift 2 ;;
        *) error "Unknown option: $1" ;;
    esac
done

# ------------------------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------------------------

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. Run as your normal user (sudo will be invoked where needed)."
fi

# Detect OS
OS="unknown"
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macos"
elif [[ -f /etc/arch-release ]]; then
    OS="arch"
else
    error "Unsupported OS. This script supports Arch Linux and macOS only."
fi

HOSTNAME="$(hostname -s)"
USERNAME="$(whoami)"

info "Detected OS: $OS"
info "Machine: $HOSTNAME"
info "User: $USERNAME"
info "Dotfiles directory: $DOTFILES_DIR"

# ------------------------------------------------------------------------------
# Load machine configuration (user-specific override takes precedence)
# ------------------------------------------------------------------------------

USER_CONF="$DOTFILES_DIR/machines/$HOSTNAME.$USERNAME.sh"
MACHINE_CONF="$DOTFILES_DIR/machines/$HOSTNAME.sh"

if [[ -f "$USER_CONF" ]]; then
    info "Loading user config: machines/$HOSTNAME.$USERNAME.sh"
    source "$USER_CONF"
elif [[ -f "$MACHINE_CONF" ]]; then
    info "Loading machine config: machines/$HOSTNAME.sh"
    source "$MACHINE_CONF"
else
    echo ""
    error "Unknown machine '$HOSTNAME'. Available machines: $(ls "$DOTFILES_DIR/machines/"*.sh 2>/dev/null | xargs -n1 basename | sed 's/\.sh$//' | tr '\n' ' ')"
fi

info "  Stow packages: $STOW_PACKAGES"

# ==============================================================================
# SYSTEM SETUP (skip with --stow-only)
# ==============================================================================

if [[ "$STOW_ONLY" == "false" ]]; then

# ------------------------------------------------------------------------------
# Step 1: Install base package manager (macOS only — Homebrew)
# ------------------------------------------------------------------------------

if [[ "$OS" == "macos" ]]; then
    if ! command_exists brew; then
        info "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for the rest of this session
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        info "Homebrew already installed, skipping"
    fi
fi

# ------------------------------------------------------------------------------
# Step 2: Install base dependencies (git, stow)
# ------------------------------------------------------------------------------

info "Installing base dependencies (git, stow)"

if [[ "$OS" == "arch" ]]; then
    sudo pacman -S --needed --noconfirm git stow base-devel
elif [[ "$OS" == "macos" ]]; then
    brew install git stow
fi

# ------------------------------------------------------------------------------
# Step 3: Install AUR helper (Arch only — yay)
# ------------------------------------------------------------------------------

if [[ "$OS" == "arch" ]]; then
    if ! command_exists yay; then
        info "Installing yay (AUR helper)"
        TMPDIR_YAY="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay.git "$TMPDIR_YAY/yay"
        (cd "$TMPDIR_YAY/yay" && makepkg -si --noconfirm)
        rm -rf "$TMPDIR_YAY"
    else
        info "yay already installed, skipping"
    fi
fi

# ------------------------------------------------------------------------------
# Step 4: Install ansible
# ------------------------------------------------------------------------------

if ! command_exists ansible-playbook; then
    info "Installing ansible"
    if [[ "$OS" == "arch" ]]; then
        sudo pacman -S --needed --noconfirm ansible
    elif [[ "$OS" == "macos" ]]; then
        brew install ansible
    fi
else
    info "Ansible already installed, skipping"
fi

# ------------------------------------------------------------------------------
# Step 5: Run ansible playbook
# ------------------------------------------------------------------------------

info "Running ansible playbook"

ANSIBLE_ARGS=(
    -i "$DOTFILES_DIR/ansible/inventory.yml"
    "$DOTFILES_DIR/ansible/playbook.yml"
    --limit "$HOSTNAME"
)

if [[ -n "$ANSIBLE_TAGS" ]]; then
    info "  Tags: $ANSIBLE_TAGS"
    ANSIBLE_ARGS+=(--tags "$ANSIBLE_TAGS")
fi

ansible-playbook "${ANSIBLE_ARGS[@]}"

fi  # end STOW_ONLY check

# ==============================================================================
# USER SETUP (skip with --ansible-only)
# ==============================================================================

if [[ "$ANSIBLE_ONLY" == "false" ]]; then

# ------------------------------------------------------------------------------
# Step 6: Deploy stow packages
# ------------------------------------------------------------------------------

info "Deploying stow packages"

for pkg in $STOW_PACKAGES; do
    if [[ -d "$DOTFILES_DIR/stow/$pkg" ]]; then
        info "  Stowing $pkg"
        stow -v -d "$DOTFILES_DIR/stow" -t "$HOME" "$pkg"
    else
        warn "  Stow package '$pkg' not found in $DOTFILES_DIR/stow/, skipping"
    fi
done

# ------------------------------------------------------------------------------
# Step 7: Set zsh as default shell
# ------------------------------------------------------------------------------

ZSH_PATH="$(command -v zsh 2>/dev/null || true)"

if [[ -n "$ZSH_PATH" ]]; then
    CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || finger "$USER" 2>/dev/null | grep Shell | awk '{print $NF}' || echo "")"
    if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
        info "Setting zsh as default shell"
        if ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
        chsh -s "$ZSH_PATH"
    else
        info "zsh is already the default shell, skipping"
    fi
else
    warn "zsh not found — install it via ansible first, then re-run"
fi

# ------------------------------------------------------------------------------
# Step 8: Install Oh My Zsh
# ------------------------------------------------------------------------------

OMZ_DIR="$HOME/.oh-my-zsh"

if [[ ! -d "$OMZ_DIR" ]]; then
    info "Installing Oh My Zsh"
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    info "Oh My Zsh already installed, skipping"
fi

# ------------------------------------------------------------------------------
# Step 9: Install Powerlevel10k theme
# ------------------------------------------------------------------------------

P10K_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}/themes/powerlevel10k"

if [[ ! -d "$P10K_DIR" ]]; then
    info "Installing Powerlevel10k theme"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    info "Powerlevel10k already installed, skipping"
fi

# ------------------------------------------------------------------------------
# Step 10: Install zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting)
# ------------------------------------------------------------------------------

ZSH_CUSTOM_PLUGINS="${ZSH_CUSTOM:-$OMZ_DIR/custom}/plugins"

if [[ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]]; then
    info "Installing zsh-autosuggestions plugin"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"
else
    info "zsh-autosuggestions already installed, skipping"
fi

if [[ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]]; then
    info "Installing zsh-syntax-highlighting plugin"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"
else
    info "zsh-syntax-highlighting already installed, skipping"
fi

# ------------------------------------------------------------------------------
# Step 11: Install TPM (Tmux Plugin Manager)
# ------------------------------------------------------------------------------

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [[ ! -d "$TPM_DIR" ]]; then
    info "Installing TPM (Tmux Plugin Manager)"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    info "TPM already installed, skipping"
fi

if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
    info "Installing tmux plugins via TPM"
    "$TPM_DIR/bin/install_plugins"
fi

fi  # end ANSIBLE_ONLY check

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------

echo ""
info "Bootstrap complete for $USERNAME@$HOSTNAME ($OS)"
info "You may need to log out and back in for shell changes to take effect."
