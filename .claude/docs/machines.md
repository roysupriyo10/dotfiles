# Machines

## Matrix

| Machine | OS | GUI | NVIDIA | Laptop | DDC/CI | Bluetooth | Stow (default) | Stow (work user) |
|---|---|---|---|---|---|---|---|---|
| **septimus** | Arch Linux | sway | RTX 3050 Mobile | yes | yes | yes | common linux gui nvidia | + work |
| **statice** | Arch Linux | no | no | no | no | no | common linux | — |
| **thalia** | macOS | aerospace | no | yes | no | yes | common macos gui | + work |
| **minerva** | macOS | aerospace | no | no | no | yes | common macos gui | — |

## Profiles

- **rs10** — personal profile. Default everywhere.
- **rs10figr** — work profile. Adds work git identity (`includeIf gitdir:~/developer/work/`), work SSH hosts, work env vars. Has override files on septimus and thalia.
- **rupsha** — girlfriend's profile on minerva. Not managed by dotfiles — she has her own user account.

## Per-User Override Files

When a machine has multiple users with different stow needs:

```
machines/thalia.sh           → STOW_PACKAGES="common macos gui"        (rs10 gets this)
machines/thalia.rs10figr.sh  → STOW_PACKAGES="common macos gui work"   (rs10figr gets this)
```

bootstrap.sh checks `machines/<hostname>.<username>.sh` first, falls back to `machines/<hostname>.sh`.

## Hostnames

Machines are identified by hostname. `bootstrap.sh` reads the config file for `$(hostname -s)`. If hostname doesn't match any machine config, bootstrap fails with a list of available machines.

## Adding a New Machine

1. Create `machines/<hostname>.sh` with `STOW_PACKAGES`
2. Create `ansible/host_vars/<hostname>.yml` with flags (`gui`, `nvidia`, `laptop`, `ddcci`, `bluetooth`)
3. Add host to `ansible/inventory.yml` under the correct group (linux/macos)
4. Optionally create `machines/<hostname>.<username>.sh` for per-user overrides
5. Run `./bootstrap.sh`
