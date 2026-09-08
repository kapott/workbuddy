# Sway keybindings

Generated from `config.tmpl` in this directory. It is the source of truth for what sway
actually does; this file is the readable index of it. The two are kept in step by hand,
so if you change one, change the other (see "Keeping this in sync" at the bottom).

`$mod` is `Mod4`, the Super key. The vim direction letters are `$left h`, `$down j`,
`$up k`, `$right l`, and every one of them also has an arrow-key twin.

Bindings marked **Z13** only exist on host `endling` (ASUS ROG Flow Z13 GZ302EAC); they
sit inside a `{{ if eq .chezmoi.hostname "endling" }}` block and render to nothing
elsewhere.

## Launching and session

| Keys | Action |
|---|---|
| `Mod+Return` | kitty |
| `Mod+Space` | wofi app launcher (`wofi --show drun`) |
| `Mod+v` | clipboard history through wofi, back into the clipboard |
| `Mod+Shift+q` | kill focused window |
| `Mod+Shift+c` | reload sway config |
| `Mod+Shift+e` | exit sway, after a swaynag confirmation |
| `Mod+Ctrl+l` | lock now (`swaylock -f`) |

swayidle also locks at 5 minutes idle, powers the outputs off at 10, and locks before
sleep.

## Focus and moving windows

| Keys | Action |
|---|---|
| `Mod+h/j/k/l` or `Mod+Left/Down/Up/Right` | focus left/down/up/right |
| `Mod+Shift+h/j/k/l` or `Mod+Shift+arrows` | move the window left/down/up/right |
| `Mod+a` | focus parent container |
| `Mod+Shift+f` | toggle focus between tiling and floating |
| `Mod` + drag | move or resize a floating window (`floating_modifier $mod normal`) |

## Workspaces

| Keys | Action |
|---|---|
| `Mod+1` … `Mod+0` | go to workspace 1 to 10 |
| `Mod+Shift+1` … `Mod+Shift+0` | move the window to workspace 1 to 10 |
| `Mod+Ctrl+Left` / `Mod+Ctrl+Right` | focus the output left/right |
| `Mod+Ctrl+<` / `Mod+Ctrl+>` | move the workspace to the output left/right |

`workspace_auto_back_and_forth yes`: pressing the current workspace's number again
jumps back to the previous one.

Do not bind `Mod+Ctrl+$left` / `Mod+Ctrl+$right` here. `$right` is `l`, so that is
literally `Mod+Ctrl+l` and it silently steals the lock binding. sway reports it as
"Overwriting binding mod4+ctrl+l".

**Z13**: workspaces 1 to 4 prefer DP-5 (the ultrawide), 9 and 10 prefer eDP-1 (the
tablet panel). Sway falls back to the focused output when the named one is absent, so
this is harmless undocked.

## Displays

| Keys | Action |
|---|---|
| `Mod+p` | wofi display menu (`display.sh menu`) |
| `Mod+Shift+p` | internal panel only, every external off |

`display.sh` talks to the running sway and writes no config, so a replug hands control
back to kanshi and the profile in `~/.config/kanshi/config`. From a terminal:

```bash
~/.config/sway/display.sh list                 # every connected output, on or off
~/.config/sway/display.sh extend right         # externals to the right of eDP-1
~/.config/sway/display.sh extend up DP-5       # one named output, above
~/.config/sway/display.sh external-only        # eDP-1 off
~/.config/sway/display.sh off DP-5             # one output off
```

It refuses to disable the last active output, and `external-only` refuses when no
external is connected. `internal-only` also repositions the panel to 0,0, which is what
you want after undocking: the sway config parks eDP-1 at 3840,320 for the docked layout
and that offset survives the ultrawide going away.

There is no mirror command. Sway has no clone mode, and two outputs sharing a position
still show separate workspaces. Mirroring means `wl-mirror`, which is not installed.
The menu offers wdisplays for a layout the script gets wrong.

## Layout

| Keys | Action |
|---|---|
| `Mod+-` | split vertically |
| `Mod+\|` | split horizontally |
| `Mod+e` | toggle split direction |
| `Mod+s` | stacking layout |
| `Mod+w` | tabbed layout |
| `Mod+z` | fullscreen toggle |
| `Mod+Shift+Space` | floating toggle |
| `Mod+Shift+-` | move the window to the scratchpad |
| `Mod+,` | show the next scratchpad window |
| `Mod+r` | enter resize mode |

In resize mode: `h/j/k/l` or the arrows resize by 10px, `Return`, `Escape` or `Mod+r`
leaves. autotiling runs in the background and picks the split direction from the focused
window's shape, so `Mod+-` and `Mod+|` are rarely needed.

## Screenshots

| Keys | Action |
|---|---|
| `Print` | whole screen to the clipboard |
| `Mod+Print` | select a region, to the clipboard |
| `Mod+Shift+Print` | select a region, saved to `~/Pictures/Screenshots/<timestamp>.png` |

## Media and hardware keys

All of these carry `--locked`, so they still work on the lock screen.

| Key | Action |
|---|---|
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | volume 5% up/down, capped at 150% |
| `XF86AudioMute` / `XF86AudioMicMute` | mute output / microphone |
| `XF86AudioPlay` / `XF86AudioNext` / `XF86AudioPrev` | playerctl play-pause, next, previous |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | screen brightness 5% up/down |

**Z13** only:

| Key | Action |
|---|---|
| `XF86KbdBrightnessUp` / `XF86KbdBrightnessDown` | keyboard cover backlight, `asus::kbd_backlight` |
| `XF86Launch4` (fan key) | next asusd performance profile, then notify which one |
| `XF86Launch1` (ROG key) | rog-control-center |
| `Mod+o` | toggle the on-screen keyboard (`toggle-osk.sh`) |

## Touchpad gestures

Four fingers sideways switched desktops under Plasma, so they switch workspaces here.
Three-finger back/forward cannot be bound globally in sway, so those slots do window
things instead.

| Gesture | Action |
|---|---|
| 4-finger swipe right | previous workspace |
| 4-finger swipe left | next workspace |
| 3-finger swipe up | fullscreen toggle |
| 3-finger swipe down | floating toggle |

## Switches (Z13)

Not keys, but they fire the same way and are easy to forget.

| Switch | Action |
|---|---|
| tablet mode on/off | `tablet-mode.sh on\|off` (keyboard cover detached/attached) |
| lid close/open | `lid.sh close\|open`, which only blanks eDP-1 when another output is up |

`autorotate.sh` follows the accelerometer through iio-sensor-proxy and remaps touch
input to match the rotation.

## Keeping this in sync

`config.tmpl` and this file are edited together, in whichever order suits you:

- change a binding in `config.tmpl`, then fix the matching row here;
- change a row here, then make `config.tmpl` match it.

After editing, check for collisions before reloading. sway prints
"Overwriting binding ..." for a duplicate and validating catches it without touching the
running session:

```bash
chezmoi execute-template --source chezmoi/ < chezmoi/private_dot_config/private_sway/config.tmpl > /tmp/sway-check
sway --validate -c /tmp/sway-check
```

Then `chezmoi apply -v` and `swaymsg reload`.

chezmoi does not deploy this file. `.chezmoiignore` lists `README.md`, so it stays in
the repo and never lands in `~/.config/sway/`.
