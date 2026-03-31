# 2026-03-10 — Full Repository Audit

## Summary

- **Total files audited**: 93
- **Files with issues**: 16
- **Total issues found**: 21 (7 critical, 7 medium, 4 minor/cosmetic, 3 design)

---

## Critical (will break things)

| # | File | Line | Issue |
|---|---|---|---|
| 1 | `ansible/playbook.yml` | all | **No tags defined** — bootstrap.sh passes `--tags` but no play/role has tags, so ansible does nothing on every machine |
| 2 | `nvim/lua/roysupriyo10/setdefaults.lua` | 46, 57 | **Unsafe formatters** — `%!prettier` and `%!black` destroy buffer contents when formatter fails or isn't installed. `silent!` suppresses the error but buffer is still replaced with stderr output |
| 3 | `sway/config.d/40-keybindings.conf` | 72 | **Broken screenshot** — `grim -g | wl-copy` has no geometry source (missing `slurp`), and sway `exec` doesn't create a shell pipeline |
| 4 | `nvim/lua/roysupriyo10/lazy.lua` | 22 | **Typo** — `lazu = false` should be `lazy = false` (snacks.nvim option silently ignored) |
| 5 | `nvim/lua/roysupriyo10/lsp/lspconfig.lua` | 134 | **Typo** — `unkwownAtRules` should be `unknownAtRules` (Tailwind @apply lint suppression not applied) |
| 6 | `nvim/after/plugin/telescope.lua` | 132 | **`load_extension("fzf")` inside `setup()` table** — should be called after setup, not inside the opts table |
| 7 | `nvim/lua/roysupriyo10/remap.lua` | 48-50 | **Augment keymaps reference uninstalled plugin** — `augmentcode/augment.vim` is commented out in lazy.lua but keymaps still reference `:Augment` commands |

## Medium (wrong but won't crash)

| # | File | Line | Issue |
|---|---|---|---|
| 8 | `nvim/after/plugin/telescope.lua` | 81 | Debug logging to `/tmp/telescope_debug.log` left in production |
| 9 | `nvim/lua/roysupriyo10/lazy.lua` | 47, 245 | Both supermaven AND codeium AI completion plugins active simultaneously — conflicting suggestions, unnecessary resource usage |
| 10 | `nvim/lua/roysupriyo10/lazy.lua` | 36-44 | bigfile.nvim redundant with snacks.nvim bigfile (both do the same thing) |
| 11 | `nvim/lua/roysupriyo10/lazy.lua` | 3 | `vim.loop` deprecated in Neovim 0.10+, should be `vim.uv` |
| 12 | `stow/macos/.shell.d/macos.sh` | 3 | Hardcoded `/opt/homebrew/bin/brew` path — fails on Intel Macs where brew is at `/usr/local/bin/brew` |
| 13 | `nvim/after/plugin/cmp.lua` | all | Empty file — cmp config is actually inline in lazy.lua. File serves no purpose |
| 14 | `nvim/lua/roysupriyo10/vscode_remap.lua` | 63, 70 | Suspicious VSCode action names (`editor.action.enableCppGlobally`, `editor.cpp.disableenabled`) — look like placeholders |

## Design Concerns

| # | File | Line | Issue |
|---|---|---|---|
| 15 | `ansible/playbook.yml` | 29 | TLP power management gated on `nvidia` flag — TLP is useful for any laptop, not just NVIDIA machines. If statice ever becomes a laptop, it won't get power management |
| 16 | `stow/common/.local/bin/` | — | Directory is empty — no scripts deployed yet (old workspace scripts had hardcoded paths and were project-specific) |
| 17 | No `README.md` | — | Repository has no README |

---

## Files Verified OK

All other files passed verification:
- `.gitignore` — covers `.claude/settings.local.json` and `.claude/worktrees/`
- `bootstrap.sh` — executable, idempotent, correct step ordering
- `.claude/` docs — CLAUDE.md, architecture.md, machines.md, workflow.md, journal
- `machines/*.sh` — all 4 machine configs correct
- `ansible/inventory.yml` — hostnames match machine configs and host_vars filenames
- `ansible/group_vars/` — linux.yml has `ansible_become: true` for system tasks
- `ansible/host_vars/` — all 4 files correct
- All ansible roles except playbook.yml tags issue
- `stow/common/` — .zshrc, .bashrc, .shell.d/common.sh (no duplication), .gitconfig (includeIf correct), .ssh/config (Include correct), .p10k.zsh, tmux.conf, lsd, imv
- `stow/linux/` — sway config (all variable chains resolve, no stale references), kanshi config (real monitor identifiers), mako, fontconfig, electron/chromium flags
- `stow/gui/` — alacritty, kitty
- `stow/macos/` — aerospace config
- `stow/nvidia/` — nvidia.sh
- `stow/work/` — gitconfig.d/work, ssh/config.d/work, work.sh
- All sway scripts (bright, reload-config.sh, status.sh) — executable, no hardcoded paths

## Verification Checklist

| Check | Result |
|---|---|
| No hardcoded `/home/roysupriyo10/` or `/home/rs10/` paths | PASS |
| No stale references to deleted sway variables | PASS |
| Sway variable chain resolves completely ($scripts_dir, $status_script, $wallpaper, $wallpapers, $bar_bg, $bar_fg, $bar_font, $brightness_step all defined) | PASS |
| All scripts executable | PASS |
| .gitignore covers claude artifacts | PASS |
| Ansible inventory matches machine configs | PASS |
| Bootstrap step ordering correct | PASS |
| No duplicate shell config between .bashrc and .zshrc | PASS |
