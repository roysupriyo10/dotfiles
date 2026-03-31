# 2026-03-11 — Ansible Redesign & Multi-User Support

## What changed

### Ansible: modular roles with proper tags
Split monolithic `packages` role into 7 focused roles: `core`, `shell`, `editor`, `dev`, `fonts`, `terminal`, `audio`. Each role is independently taggable.

Rewrote `playbook.yml` — single play with tagged roles and `when:` conditions at play level. Running without `--tags` executes everything; host_vars flags gate automatically.

### Fixed broken tag system
Old: machine configs had `ANSIBLE_TAGS` but playbook had zero `tags:` directives → no-op.
New: tags defined on every role in playbook. `ANSIBLE_TAGS` removed from machine configs. Tags are now a developer convenience via `--ansible-tags` flag, not required for bootstrap.

### Fixed wrong gating flags
- TLP (power role) now gated on `laptop` flag, not `nvidia`
- ddcci role now gated on `ddcci` flag, not `nvidia`
- Added `laptop`, `ddcci`, `bluetooth` flags to all host_vars
- NVIDIA workaround in ddcci role conditionally deployed only when `nvidia` is also true

### Removed hardcoded username
- Deleted `ansible_user: rs10` from `group_vars/all.yml`
- Changed `{{ ansible_user }}` references to `{{ ansible_env.USER }}` (auto-detected)
- Removed per-host `ansible_user` from inventory

### Multi-user support
- Machine configs now only define `STOW_PACKAGES` (no ANSIBLE_TAGS)
- Per-user override files: `machines/<hostname>.<username>.sh`
- bootstrap.sh checks `machines/$(hostname -s).$(whoami).sh` first, falls back to `machines/$(hostname -s).sh`
- Created `septimus.rs10figr.sh` and `thalia.rs10figr.sh` override files
- Ansible stays machine-level (system config shared across all users)

### Bootstrap improvements
- Added `--stow-only`, `--ansible-only`, `--ansible-tags` CLI flags
- Ansible now runs without `--tags` by default (runs all roles, `when:` handles gating)
- Ansible runs before stow (packages installed before configs symlinked)
- Shows user and machine in output

### macOS brew path fix
`macos.sh` now checks both `/opt/homebrew/bin/brew` (Apple Silicon) and `/usr/local/bin/brew` (Intel).

### Services role cleanup
- Moved pipewire/wireplumber services to `audio` role
- Bluetooth service gated on `bluetooth` flag
- Base services (NetworkManager, sshd) always enabled on Linux

## Files changed
- `ansible/playbook.yml` — complete rewrite
- `ansible/inventory.yml` — removed hardcoded ansible_user
- `ansible/group_vars/all.yml` — removed hardcoded username, added ansible_connection
- `ansible/host_vars/*.yml` — added laptop, ddcci, bluetooth flags
- `ansible/roles/` — added core, shell, editor, dev, fonts, terminal, audio; deleted packages
- `ansible/roles/gui/` — absorbed polkit/seatd/portals from old gui role + sway packages from old packages role
- `ansible/roles/services/` — removed pipewire (moved to audio), gated bluetooth
- `ansible/roles/power/` — added TLP package install, standalone
- `ansible/roles/ddcci/` — added ddcutil install, conditional nvidia workaround
- `machines/*.sh` — removed ANSIBLE_TAGS, added per-user override files
- `bootstrap.sh` — multi-user support, CLI flags, reordered steps
- `stow/macos/.shell.d/macos.sh` — dynamic brew path
- `.claude/docs/architecture.md` — updated with new ansible roles table, multi-user section
- `.claude/docs/machines.md` — updated with per-user override docs
- `.claude/CLAUDE.md` — updated with ansible roles table, multi-user principle

## Decisions
- Tags are for developer convenience (incremental runs), not machine config. `when:` conditions are the machine gating mechanism.
- `laptop` is a separate flag from `nvidia` — any laptop gets TLP, regardless of GPU.
- `ddcci` is a separate flag from `nvidia` — any machine with external monitors can use DDC/CI.
- Per-user overrides fully specify STOW_PACKAGES (no additive/subtractive complexity).
- Ansible runs before stow in bootstrap (install packages first, then symlink configs that depend on them).
