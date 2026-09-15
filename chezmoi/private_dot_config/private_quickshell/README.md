# The bar

Quickshell, a QtQuick shell toolkit. Every file here is QML, and `qs` loads
`shell.qml` because `~/.config/quickshell/shell.qml` is the config it picks with
no `-c` flag. Not deployed by chezmoi: `.chezmoiignore` drops `**/README.md`.

Sway starts `~/.config/sway/bar.sh` from `exec_always`, and that script runs
`launch.sh` here when `qs` is on `$PATH`. Without it there is waybar, whose
config is still in the repo for distributions that do not package quickshell.
Quickshell watches its own QML and reloads on save, so editing a file here is
enough; the launch script only exists because `exec_always` fires again on a sway
reload and two instances would fight over the same exclusive zone.

## Layout

One file per module, all in this directory. QML resolves types from the
directory a file sits in, so a subdirectory would need an import path and a
generated `qmldir` for nothing.

| File | What it is |
|---|---|
| `shell.qml` | root, one `Bar` per screen |
| `Bar.qml` | the panel window and the order of the modules |
| `Pill.qml` | icon plus reading plus click target, the shape of every right-hand module |
| `Tooltip.qml` | popup that can draw outside the 30px bar |
| `Theme.qml` | the palette and the metrics, singleton |
| `Glyph.qml` | every icon by codepoint, singleton |
| `Host.qml.tmpl` | per-machine hardware paths, singleton, rendered by chezmoi |
| `Osd.qml` | the IPC entry point for overlays, singleton |
| `BigClock.qml` | the time and date across the focused output, held up by `Mod+t` |

The modules themselves: `Workspaces`, `SwayMode`, `WindowTitle`, `IdleInhibit`,
`Volume`, `Backlight`, `BluetoothStatus`, `NetworkStatus`, `CpuUsage`,
`MemoryUsage`, `TemperatureStatus`, `PowerProfile`, `BatteryStatus`, `Clock`,
`Tray`.

`BigClock` is a second surface per screen, not a bar module. It sits hidden until sway's
`Mod+t` runs `qs ipc call osd clock`; `Osd.qml` turns that call into a signal and every
BigClock listens, but only the one on the output sway calls focused draws. Font size and
padding are `osd*` in `Theme.qml`.

It stays up while the key is down. sway's `--release` binding calls `clockRelease` and
that hides it, with two timers around the hold. `osdDuration` is a floor: a tap and its
release land some 20ms apart, and a flash that short is a flicker, so the clock stays for
the full second anyway. `osdHoldLimit` is a ceiling at a minute, for the case where the
release never arrives because sway reloaded mid-press; without it the overlay would cover
the screen until quickshell restarts.

Under the time it prints `Tue 15 Sep 2026 · week 38 · Q3 (16 days left)`. Qt's format
strings have no token for the ISO week or the quarter, so the pure functions at the top of
`BigClock.qml` count both. The week follows ISO 8601, where a week belongs to the year
holding its Thursday, so early January can read `week 53`. The day count includes today,
so 30 September says `1 day left`.

Names avoid `Bluetooth` and `Network` on purpose: those are the singletons
`Quickshell.Bluetooth` and `Quickshell.Networking` export, and a local type of
the same name shadows them.

## Interactions

| Module | Left click | Right click | Scroll |
|---|---|---|---|
| Workspace | switch to it | | |
| Idle inhibitor | toggle | | |
| Volume | pavucontrol | mute | volume 5% |
| Backlight | | | brightness 5% |
| Bluetooth | blueman-manager | | |
| Network | | `kitty -e nmtui` | |
| CPU | `kitty -e btop` | | |
| Power profile | cycle | rog-control-center | |
| Clock | show the date | | |
| Tray item | activate | menu | |

## Icons

`Glyph.qml` holds the codepoints. Check the glyph **name**, not just that the
codepoint resolves to something: two of the values in the first draft were
present in the font and were the wrong icon.

```bash
python -c "from fontTools.ttLib import TTFont; \
  f = TTFont('/usr/share/fonts/TTF/HackNerdFontMono-Regular.ttf'); \
  print([t.cmap.get(0xefc5) for t in f['cmap'].tables])"
```

## Checking a change

There is no linter. Run it and read the log:

```bash
qs -p ~/Documents/git/personal/workbuddy/chezmoi/private_dot_config/private_quickshell
```

That will not work straight from the source directory, because `Host.qml` only
exists after chezmoi renders `Host.qml.tmpl`. Render it into a scratch copy
first:

```bash
d=$(mktemp -d)
cp chezmoi/private_dot_config/private_quickshell/*.qml "$d"
chezmoi execute-template --source chezmoi \
  < chezmoi/private_dot_config/private_quickshell/Host.qml.tmpl > "$d/Host.qml"
qs -p "$d"
```

A QML error is fatal and prints the whole chain, from `shell.qml` down to the
line that failed. `Configuration Loaded` with no `ERROR` above it means the tree
built; it does not mean a module found its data.

Firing the IPC by hand needs the same config selected, otherwise `qs ipc` looks at the
running bar instead: `qs -p "$d" ipc call osd clock`. Screenshotting the result needs a
beat after the call, because `grim` run in the same breath catches the frame before the
surface maps and shows nothing.

`WARN quickshell.I3.ipc: I3 event socket disconnected.` shows up once at startup
and is harmless. Workspaces, the focused-workspace highlight and the mode
indicator all keep working after it.

## Things that bit

**A binding over a lazily populated list runs before the list exists.**
`DesktopEntries.heuristicLookup` is a plain function, so a binding calling it has
nothing to re-evaluate on when the `.desktop` scan finishes. Reading
`DesktopEntries.applications.values.length` first is what gives the binding
something to depend on. Without it the first window of a session never gets an
icon and every later one does, which reads as a font problem rather than a
timing one.

**`PwObjectTracker` is not optional.** Quickshell only binds a pipewire node's
audio data while something tracks it. Drop the tracker and volume sits at 0%
with no error.

**Controls popups cannot leave a layer surface.** `QtQuick.Controls`' `ToolTip`
renders clipped inside the 30px bar and in the Fusion style's colours.
`Tooltip.qml` is a `PopupWindow`, which is a real xdg_popup and draws over the
windows below.

**`Component.onCompleted` needs a QtQml import.** `shell.qml` got away with importing
only `Quickshell` until it needed that line. Without `import QtQml` the attached type
does not exist and the whole shell refuses to load with
`Non-existent attached object`, which names no file you would think to look at.

**`I3.focusedMonitor` is null until someone asks for the monitor list.** Reading it is
not what populates it. `Workspaces` happens to trigger the sync by reading
`I3.workspaces`, so anything relying on the property works by accident as long as that
module exists; `shell.qml` calls `I3.refreshMonitors()` at startup so BigClock does not.
