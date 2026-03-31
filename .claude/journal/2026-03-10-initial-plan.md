# 2026-03-10 — Initial Plan & Repository Setup

## What happened

Started a complete dotfiles rebuild from a clean slate. Old dotfiles had accumulated problems over 2-3 years:
- Hardcoded username (`roysupriyo10`) in scripts that broke when user changed to `rs10`
- Duplicated shell config between .bashrc and .zshrc
- Branch-per-machine pattern causing cherry-pick hell
- `status.sh` polling ddcutil every second (2-5s per call, hammering CPU)
- Hardcoded PulseAudio source ID `--source 59` breaking on reboot
- No NVIDIA dGPU power management (RTX 3050 Mobile draws power even when idle)
- `install.sh` was a 1-line placeholder — no real deployment mechanism

## Decisions made

1. **stow + ansible** over chezmoi/Home Manager — stow preserves edit-and-reflect workflow (symlinks), ansible handles sudo-level system config. No templating needed.
2. **Selective stow packages** over branches — one branch, different packages deployed per machine. Profile split via file-existence, not code branching.
3. **ddcci-driver-linux + brightnessctl** over raw ddcutil — kernel module exposes monitors as backlight devices, brightnessctl controls them in <50ms. Focus-aware wrapper script maps sway output to backlight device at runtime.
4. **wpctl** over pamixer with hardcoded source — uses `@DEFAULT_AUDIO_SOURCE@` for mic, `@DEFAULT_AUDIO_SINK@` for speakers.
5. **RTD3 with `NVreg_DynamicPowerManagement=0x03`** for NVIDIA power — Ampere-optimized, should bring dGPU to 0W when idle.
6. **No OSD** — sway status bar already shows brightness/volume, SwayOSD unnecessary.
7. **`.claude/` in repo** — CLAUDE.md, docs, journal, rules all committed to git. Session state (plans, memory) stays in global `~/.claude/`. Context travels with the repo across machines.

## Alternatives considered

- **chezmoi**: Better templating but copies files instead of symlinking — worse daily workflow
- **Home Manager on Arch**: Can't touch /etc/, requires nix alongside pacman, steep learning curve
- **ansible-only**: One tool but clunkier daily editing (edit in repo → run playbook)
- **SwayOSD**: Nice visuals but unnecessary overhead when status bar shows the same info

## Later in the session

8. **kanshi** replaces the custom `generate-positions.sh` + display variables system. Monitors identified by make/model/serial (persistent across ports), profiles auto-switch on hotplug. `03-displays.conf`, `04-monitor-positions.conf`, and `generate-positions.sh` all deleted.
9. **nwg-displays** added as GUI tool for initial visual monitor arrangement — positions go into kanshi config.
10. **`bright` script improved** — now maps focused sway output to the correct ddcci backlight device via DRM connector I2C bus matching. Works with multiple external monitors.
11. **Bootstrap improved** — handles Homebrew install, yay (AUR helper), oh-my-zsh, p10k, zsh plugins, TPM + tmux plugin install, zsh as default shell. Fully idempotent.

## Open questions

- ddcci-driver-linux NVIDIA udev workaround needs testing on septimus
- TLP config may need tuning after initial deployment
- kanshi profiles need real monitor identifiers (run `swaymsg -t get_outputs | jq` on each machine)
- p10k.zsh config was recovered as-is from old setup — may need refresh
