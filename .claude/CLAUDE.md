# Dotfiles — Project Instructions

## Overview

Reproducible, multi-machine, multi-user dotfiles for Arch Linux + macOS. Uses **stow** for symlinking (edit-and-reflect workflow) and **ansible** for system-level config only.

No templating. Profile/OS differences handled by selective stow packages, per-user overrides, runtime detection, git `includeIf`, and SSH `Include`.

## Architecture

See @.claude/docs/architecture.md for full system design.
See @.claude/docs/machines.md for machine matrix and profiles.

## Key Principles

- **No hardcoded usernames or paths** — always use `$HOME`, `$(whoami)`, `ansible_env.USER`
- **No duplicated config** — shared shell config in `.shell.d/common.sh`, sourced by both .zshrc and .bashrc
- **No branch-per-machine** — one branch, selective stow packages
- **Symlinks everywhere** — edit a dotfile, it reflects immediately
- **Ansible for sudo-only tasks** — packages, /etc/ files, systemd services
- **Modular ansible roles** — each role independently taggable, gated by host_vars flags
- **Multi-user** — `machines/<hostname>.<username>.sh` overrides default stow packages per user
- **pass for secrets** — never store credentials in the repo
- **Auto-detect hardware at runtime** — no hardcoded monitor names, device IDs, or PulseAudio source numbers

## Stow Packages

| Package | Deployed on | Contents |
|---|---|---|
| `common` | All machines | nvim, tmux, shell, git, ssh base, scripts, lsd, imv |
| `linux` | Arch machines | sway, kanshi, mako, fontconfig, electron/chromium flags |
| `macos` | macOS machines | aerospace |
| `gui` | GUI machines | alacritty, kitty |
| `work` | Work-profile users | work git identity, work SSH hosts, work env |
| `nvidia` | NVIDIA machines | NVIDIA user-level env vars |

## Ansible Roles

| Role | Tag | Gated by | What |
|---|---|---|---|
| `core` | core | always | base tools, gnupg, pass |
| `shell` | shell | always | zsh, fzf, bat, lsd, ripgrep |
| `editor` | editor | always | neovim, tmux |
| `dev` | dev | always | go, node, python, rust, docker |
| `fonts` | fonts | always | nerd fonts |
| `services` | services | always | NetworkManager, sshd, bluetooth, docker |
| `gui` | gui | `gui` flag | sway, polkit, seatd, kanshi |
| `terminal` | terminal | `gui` flag | kitty, alacritty |
| `audio` | audio | `gui` flag | pipewire, wireplumber |
| `nvidia` | nvidia | `nvidia` flag | drivers, RTD3 power |
| `ddcci` | ddcci | `ddcci` flag | DDC/CI kernel module |
| `power` | power | `laptop` flag | TLP |

## Rules

See @.claude/rules/workflow.md for mandatory workflow rules.

## Journal

Implementation history in `.claude/journal/` — always check recent entries for context on ongoing work.
