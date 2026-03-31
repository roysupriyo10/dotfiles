# Architecture

## Tools

| Tool | Purpose | Scope |
|---|---|---|
| **stow** | Symlinks dotfiles into `$HOME` | User-level config only |
| **ansible** | System config (packages, /etc/ files, services) | Requires sudo |
| **pass** | Secrets management | GPG-encrypted, git-backed |

## Why stow + ansible (not chezmoi, not Home Manager)

- **stow**: Same workflow as lndir — edit a file, change reflects immediately via symlink. No rebuild cycle, no `apply` command for daily edits.
- **ansible**: Only tool that can manage both system-level files (/etc/modprobe.d, udev rules, systemd services) and install packages via pacman/brew. Runs once per setup or when system config changes.
- **Not chezmoi**: Copies files instead of symlinking — requires `chezmoi apply` after every edit. Worse daily workflow.
- **Not Home Manager**: Can't touch /etc/ on non-NixOS. Requires nix package manager alongside pacman. Steep learning curve for marginal gain.

## Profile/OS Split — No Branching

All differences handled without git branches:

1. **Selective stow packages** — each machine deploys only the packages it needs
2. **Per-user overrides** — `machines/<hostname>.<username>.sh` overrides default stow packages for that user
3. **Runtime OS detection** — `uname -s` in shell scripts
4. **File-existence sourcing** — `.shell.d/*.sh` files auto-sourced if present
5. **Git `includeIf`** — work identity activates per-directory, silently ignored if work gitconfig doesn't exist
6. **SSH `Include config.d/*`** — work hosts only present if work stow package deployed

## Directory Layout

```
stow/<package>/ mirrors $HOME structure
  e.g., stow/common/.config/nvim/ → ~/.config/nvim/
```

`stow -t $HOME <package>` creates symlinks from the stow directory into $HOME.

## Multi-User Support

Machine config and user config are separated:

- `machines/<hostname>.sh` — default stow packages for the machine
- `machines/<hostname>.<username>.sh` — per-user override (optional)
- `ansible/host_vars/<hostname>.yml` — machine-level flags (system config, shared across all users)

bootstrap.sh checks for user-specific config first, falls back to machine default. Ansible (system-level) runs the same regardless of user. Stow (user-level) varies per user.

## Bootstrap Flow

1. `bootstrap.sh` loads `machines/$(hostname).$(whoami).sh` or falls back to `machines/$(hostname).sh`
2. Installs stow + ansible via pacman (or brew on macOS)
3. Runs `ansible-playbook` with `--limit $(hostname)` — host_vars `when:` conditions gate roles automatically
4. Runs `stow` for each package listed in user/machine config
5. Installs zsh ecosystem (oh-my-zsh, p10k, plugins) and tmux plugins

Supports incremental runs:
- `./bootstrap.sh --stow-only` — re-deploy stow packages without ansible
- `./bootstrap.sh --ansible-only` — re-run ansible without stow
- `./bootstrap.sh --ansible-tags "gui,nvidia"` — run specific ansible roles

## Ansible Architecture

Modular roles, each independently taggable. Machine-specific gating via `when:` conditions from host_vars flags.

| Role | Tag | Gated by | What |
|---|---|---|---|
| `core` | core | always | git, stow, curl, gnupg, pass |
| `shell` | shell | always | zsh, fzf, bat, lsd, ripgrep, fd, zoxide |
| `editor` | editor | always | neovim, tmux |
| `dev` | dev | always | go, node, python, rust, docker |
| `fonts` | fonts | always | nerd fonts, noto |
| `services` | services | always | NetworkManager, sshd; bluetooth/docker gated individually |
| `gui` | gui | `gui` flag | sway, polkit, seatd, portals, kanshi, brightnessctl |
| `terminal` | terminal | `gui` flag | kitty, alacritty |
| `audio` | audio | `gui` flag | pipewire, wireplumber + user services |
| `nvidia` | nvidia | `nvidia` flag | nvidia drivers, RTD3 power, udev rules |
| `ddcci` | ddcci | `ddcci` flag | ddcci-driver-linux kernel module |
| `power` | power | `laptop` flag | TLP config and service |

Host vars flags: `gui`, `nvidia`, `laptop`, `ddcci`, `bluetooth`

## Display Management

- **kanshi** daemon auto-detects monitors by make/model/serial (persistent across ports)
- Profile-based: define layouts in `~/.config/kanshi/config`, auto-switches on hotplug
- **nwg-displays** for visual GUI arrangement — export positions into kanshi config
- Sway config only sets wallpapers and global settings — kanshi handles resolution/position/scale

## Brightness & Volume

- **ddcci-driver-linux** kernel module exposes external DDC monitors as `/sys/class/backlight/ddcci*`
- **brightnessctl** controls both laptop backlight and external monitors via ddcci (<50ms)
- **Focus-aware `bright` script** detects which sway output has focus, maps to correct ddcci device via DRM connector I2C bus matching — works with multiple external monitors
- **wpctl** for volume with `@DEFAULT_AUDIO_SINK@` / `@DEFAULT_AUDIO_SOURCE@` — no hardcoded IDs
- **status.sh** reads from `/sys/class/backlight/` (instant) instead of polling ddcutil
