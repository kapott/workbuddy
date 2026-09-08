# install-sway.sh leaves the ~/.config directories empty

## Context

Rolling the sway configuration out on `endling` with `./install-sway.sh --config-only`,
from a Claude Code session, so with no controlling terminal. The machine already had
`~/.config/{sway,quickshell,waybar,mako,wofi,swaylock,kanshi}` from an earlier run.

## Problem

The script moved all seven directories aside to `<name>.<timestamp>.bak`, then stopped:

```
== Applying the sway configuration with chezmoi
.config/kanshi has changed since chezmoi last wrote it?
chezmoi: .config/kanshi: could not open a new TTY: open /dev/tty: no such device or address
```

`~/.config/sway` no longer existed. The running sway session kept working, because it had
already read its config, but `swaymsg reload` would have failed and a new session would
not have started.

`chezmoi apply` compares the destination against the entry state it recorded in
`~/.config/chezmoi/chezmoistate.boltdb` and asks before overwriting anything that changed
since. The prompt needs `/dev/tty`. Without one chezmoi does not fall back to a default,
it exits, and everything after that entry stays unwritten.

## Solution

Pass `--force`. The backup step above the apply has already moved every target aside, so
chezmoi's overwrite guard has nothing left to protect:

```bash
chezmoi apply --source "$SRC" --destination "$HOME" --force -v "${TARGETS[@]}"
```

To recover a run that already failed, apply the same targets by hand:

```bash
chezmoi apply --source ~/Documents/git/personal/workbuddy/chezmoi --destination "$HOME" --force -v \
    ~/.config/{sway,quickshell,waybar,mako,wofi,swaylock,kanshi} \
    ~/.config/xdg-desktop-portal/sway-portals.conf
sway --validate --config ~/.config/sway/config
```

The `.bak` directories from the failed run are then duplicates of the ones from the run
before it, and can go.

### Hypotheses that were wrong

**Not the backup step.** The `mv` commands did exactly what they promise and the content
was never lost, only renamed. Reading the empty `~/.config/sway` first makes it look like
the script deletes rather than moves.

**Not chezmoi being uninitialised.** This machine has no `~/.config/chezmoi/chezmoi.toml`
and no source directory, so every command needs `--source`, and chezmoi warns about it on
every run. That warning is unrelated; the state database exists regardless and is what
drives the prompt.

See also [install-sway-stops-after-the-backup-step.md](install-sway-stops-after-the-backup-step.md),
a second way the same script ends early.
