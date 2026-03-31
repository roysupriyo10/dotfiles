# Workflow Rules

## After Every Task Completion

1. **Update `.claude/journal/`** — add or update the current date's entry with what was done, decisions made, and any open questions
2. **Validate `.claude/docs/`** — if any architectural decisions changed, update the relevant doc. If new docs are needed, create them.
3. **Validate `.claude/CLAUDE.md`** — if the project structure or key principles changed, update CLAUDE.md to reflect reality
4. **Check for stale information** — if any doc references something that no longer exists or works differently, fix it immediately

## Before Making Changes

- Always confirm with the user before modifying plan files or making architectural decisions
- The user is the best source of context — ask them first before reaching for exploration tools
- Read existing code before suggesting modifications

## Code Standards

- Use `$HOME` never hardcoded paths like `/home/rs10/`
- Scripts must auto-detect hardware (monitors, audio sources, backlight devices) at runtime
- No duplicate config between .bashrc and .zshrc — shared config goes in `.shell.d/common.sh`
- Sway config uses the modular `config.d/` numbered file convention
