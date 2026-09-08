# The ROG fan key does not change the power profile, and says nothing

## Context

Host `endling`, ASUS ROG Flow Z13 GZ302EAC, sway. `asusctl 6.4.0-2`, `asusd` active,
`power-profiles-daemon 0.30-3` also active.

The fan key on the Z13 emits `XF86Launch4` and had a binding in
`chezmoi/private_dot_config/private_sway/config.tmpl` since the i3 to sway migration.

## Problem

Pressing the fan key did nothing at all. No profile change, and no notification either,
which is what made it hard to notice: there was no failure to see, just a key that had
quietly stopped meaning anything.

The binding was:

```
bindsym XF86Launch4 exec asusctl profile -n && notify-send "ASUS profile" "$(asusctl profile -p)"
```

Both flags are gone in asusctl 6.4.0:

```
$ asusctl profile -p
Unrecognized argument: -p

Run asusctl --help for more information.
```

They became subcommands. `asusctl profile --help` now lists `next`, `list`, `get`, `set`
and `tuning`.

The missing notification is the `&&`. `asusctl profile -n` exits non-zero on the usage
error, so the right-hand side never runs and the key produces no feedback of any kind.

## Solution

Point the binding at a wrapper script instead of calling `asusctl` inline, so the CLI is
named in one file rather than two:

```
bindsym XF86Launch4 exec ~/.config/sway/power-profile.sh next
```

`chezmoi/private_dot_config/private_sway/executable_power-profile.sh` takes `status`,
`get`, `next`, `set <profile>` and `list`. The same script backs the waybar module
`custom/power-profile`, which is the actual reason for it existing. Two call sites for a
CLI that has already renamed its flags once is two places to forget.

> The bar became quickshell later and the script changed with it: `status` and the
> `SIGRTMIN+8` signal are gone, replaced by `publish`, which writes the profile to
> `$XDG_RUNTIME_DIR/power-profile` for the bar to watch. Everything below describes the
> waybar arrangement as it was when this was written; the fix itself, one wrapper script
> instead of two call sites, is what carried over.

Current syntax, for reference:

```bash
asusctl profile get                  # Active profile: Performance
asusctl profile list                 # Quiet, Balanced, Performance
asusctl profile next
asusctl profile set Balanced
asusctl profile set -a Performance   # profile to use on AC
asusctl profile set -b Quiet         # profile to use on battery
```

The waybar module polls every 30 seconds and also repaints on `SIGRTMIN+8`, which the
script sends after it changes anything. Polling is not belt-and-braces here: `asusd`
switches profile by itself when the power source changes, so the bar goes stale on unplug
with no signal to react to.

Verified by cycling and reading it back:

```
before: Performance
after:  Quiet
{"text":"PRF Quiet","class":"quiet",...}
```

Hypotheses that turned out wrong along the way:

- **The key does not reach sway, so the symbol is wrong.** Wrong. `XF86Launch4` is
  correct for the fan key on this machine, and `XF86Launch1` for the ROG key next to it.
  Checking the keysym first is the natural instinct and it costs you the real cause.
- **power-profiles-daemon is fighting asusd for the profile.** Wrong as the cause of this
  symptom, though the overlap is real and worth knowing about. Both daemons are active and
  both write `/sys/firmware/acpi/platform_profile`, whose choices here are `quiet balanced
  performance`, under different names for the same three states. Last writer wins. That can
  surprise you later, but it was not why the key did nothing.
- **Every other hardware-key binding is probably rotten too.** Wrong, and worth having
  checked rather than assumed. Auditing the whole section found only this one: `wpctl -l`,
  `playerctl play-pause|next|previous`, `brightnessctl -d asus::kbd_backlight` with the
  device present, `rog-control-center` and `wvkbd-mobintl` all still resolve.

## Notes

A binding whose command exits non-zero is invisible in sway. Nothing is logged, and a
`&&` chain swallows the notification that would have told you. When adding a binding that
shells out to a vendor CLI, run the command by hand first, and prefer a script that can
fail loudly over an inline one-liner that cannot.
