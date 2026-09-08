# Sway leaves a black screen after unplugging the external monitor

## Context

Host `endling`, ASUS ROG Flow Z13 GZ302EAC, sway from
`chezmoi/private_dot_config/private_sway/config.tmpl`. Two outputs, the built-in panel
`eDP-1` and an LG 38WN95C ultrawide as `DP-5`.

`display.sh external-only`, bound behind the `Mod+p` menu, turns the panel off and leaves
only the external running. That is the desk setup. The laptop then travels to a client
site.

## Problem

`external-only` disables the panel at runtime:

```bash
swaymsg output eDP-1 disable
```

That is session state, not config, so it outlives the monitor that justified it. Unplug
the ultrawide with `external-only` still in effect and sway has zero enabled outputs.

Nothing renders, so no keybinding can help. You cannot see the display menu you would use
to fix it, and you cannot see whether the key you pressed did anything. On a laptop at a
client site with no second screen to plug back in, that is a session you cannot recover
without switching VT or reaching for `swaymsg` blind.

The guards that look like they cover this do not. `display.sh off` refuses to disable the
last active output, and `external-only` refuses when no external is connected, but both
checks run when you invoke the command. Neither says anything about a cable leaving
afterwards.

Reproduced without touching the cable:

```bash
swaymsg output eDP-1 disable
swaymsg output DP-5 disable
swaymsg -t get_outputs -r | jq '[.[] | select(.active)] | length'
# 0
```

## Solution

Two layers, and it matters which one does what.

kanshi handles the ordinary case already. Its `tablet` profile lists `eDP-1` on its own,
so losing `DP-5` changes the connected set, flips the matched profile from `docked` to
`tablet`, and re-enables the panel. That works, and it is the path this normally takes.

kanshi is not enough on its own for two reasons. It is a single unsupervised process,
started from `config.tmpl` with `exec kanshi`, with no restart and no unit. And it only
acts when the remaining outputs match a profile it has, so an unknown projector at a
client site matches nothing.

`panel-guard.sh` is the floor under both. It subscribes to sway's output events, waits a
second so kanshi gets first refusal, then counts active outputs. Zero means it enables the
panel and parks it at 0,0:

```bash
exec 3< <(swaymsg -t subscribe -m -r '["output"]')
...
rescue() {
    [ "$(count_active)" = 0 ] || return 0
    panel_present || return 0
    swaymsg output "$PANEL" enable
    swaymsg output "$PANEL" position 0 0
}
```

It only ever enables, never disables, so it cannot fight `external-only` while an external
is still attached. Its lifetime is tied to `$SWAYSOCK` with a trap that reaps the `swaymsg
subscribe` child, the same shape `autorotate.sh` uses, because sway does not reliably reap
what `exec` starts and a blocking read on an idle subscription would outlive the session.

It starts from `config.tmpl` right after kanshi:

```
exec ~/.config/sway/panel-guard.sh
```

Verified by driving sway into the state on purpose:

```
=== ZERO-OUTPUT STATE ENTERED at 10:06:27 ===
active outputs: 0
=== AFTER 6s ===
eDP-1 active=true 0,0
panel-guard: no active output left, re-enabled eDP-1
```

Check it is alive with `pgrep -f panel-guard.sh`. It logs to the sway log and fires a
notification when it acts. `exec` lines do not re-run on `swaymsg reload`, so after adding
it to a running session you have to start it by hand once:

```bash
setsid nohup ~/.config/sway/panel-guard.sh >/dev/null 2>&1 &
```

Hypotheses that turned out wrong along the way:

- **`display.sh` already refuses to leave you with a dark screen.** Wrong for this path.
  The refusal lives in `off()` and in the "no external connected" check in
  `external_only()`. Both are call-time checks. Neither survives the cable being pulled
  ten minutes later.
- **kanshi always catches it, so nothing more is needed.** Half right. kanshi does catch
  the two-profile desk case, which is why this had not bitten yet. It catches nothing if
  it has died, and nothing when the connected set matches no profile, which is exactly the
  unfamiliar-projector case where you are most likely to have used `external-only`.
- **A sway keybinding could be the escape hatch.** Wrong, and it is the tempting fix. With
  zero outputs enabled there is no feedback at all, so a binding you cannot verify pressing
  is not a recovery path.
