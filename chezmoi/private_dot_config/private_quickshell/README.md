# The shell

The bar, the menu, the panels, the on-screen displays and the notification
daemon. Quickshell, a QtQuick shell toolkit. Every file here is QML, and `qs` loads
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
| `Osd.qml` | the IPC entry point for overlays, and the level keys, singleton |
| `BigClock.qml` | the time and date across the focused output, held up by `Mod+t` |
| `OsdLevel.qml` | the volume / brightness / keyboard light bar |
| `Ipc.qml` | an `IpcHandler` that a sway binding can reach as well |
| `IpcRegistry.qml` | every `Ipc` handler, so `Bindings` can call them, singleton |
| `Bindings.qml` | turns `nop qs <target> <method>` bindings into calls, singleton |
| `ShellState.qml` | the shared switches (idle inhibit, bar, do not disturb), singleton |
| `Menu.qml` | the `Mod+space` menu: state and window, singleton |
| `MenuRow.qml` | one row of the menu |
| `MenuTree.js` | the static menus as data, and the search |
| `Frecency.js` | z's frecency, pure functions |
| `Usage.qml` | what the menu was used for, stored for frecency, singleton |
| `*Panel.qml` | rows for the live menus: audio, bluetooth, network, tailscale, power, keys |
| `Notifications.qml` | the notification server, popups list and history, singleton |
| `NotificationPopups.qml`, `NotificationCard.qml` | the popups |

The modules themselves: `Workspaces`, `SwayMode`, `WindowTitle`, `DoNotDisturb`, `IdleInhibit`,
`Volume`, `Backlight`, `BluetoothStatus`, `NetworkStatus`, `CpuUsage`,
`MemoryUsage`, `TemperatureStatus`, `PowerProfile`, `BatteryStatus`, `Clock`,
`Tray`.

`BigClock` is a second surface per screen, not a bar module. It sits hidden until sway's
`Mod+t` binding (`nop qs osd clock`) reaches `Osd.qml`, which turns it into a signal; every
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

## Key bindings without a process

sway binds the shell's keys as `nop qs <target> <method> [arg]`. `nop` runs nothing, but
sway still sends the binding event, command text included, to every IPC subscriber.
`Bindings.qml` subscribes, parses the text and calls the matching function on an `Ipc`
handler through `IpcRegistry`. The same function answers `qs ipc call <target> <method>`
from a script. Measured on endling on 2026-10-09, 100 presses each, median key to handler:

| Path | ms |
|---|---|
| `nop` + `Bindings.qml` | 2.0 |
| `exec echo x \| socat` to a QML `SocketServer` | 5.2 |
| `exec qs ipc call` | 19.0 |

`exec qs ipc call` starts a whole Qt client per press. The sway config sets the commands as
variables (`$launcher`, `$volup`, ...) in one block, chosen at `chezmoi apply` by whether
`qs` is on `$PATH`, so the waybar fallback still gets wofi and wpctl.

Targets: `menu` (toggle/open/close `<id>`), `osd` (clock, volume, mute, micMute,
brightness, kbdLight), `state` (toggle `<switch>`), `notifications` (dismissNewest,
dismissAll, invokeNewest, clearHistory).

## The menu and the panels

`Mod+space` opens the root menu, Omarchy's walker menu cut down to this machine. Typing at
the top searches every leaf of the tree and every installed app. The static menus are data
in `MenuTree.js`. Apps, the panels and the notification history are menus whose rows come
live from a provider singleton (`AudioPanel.qml` and siblings). They share the frame, the
search and the keys: Up/Down or Ctrl+j/k, Enter, Right into a submenu, Left/Right on a
value such as volume, Escape to clear, back, close.

| Keys | Opens |
|---|---|
| `Mod+space` | root menu |
| `Mod+Shift+e` | system (lock, suspend, log out, reboot, shut down) |
| `Mod+Ctrl+c` / `o` / `h` | capture / toggle / hardware |
| `Mod+Ctrl+a` / `b` / `w` / `t` / `e` | audio / bluetooth / network / tailscale / power |
| `Mod+slash` | every key binding, read from the running sway config |
| `Mod+n` / `Mod+Shift+n` / `Mod+Alt+n` | dismiss newest / dismiss all / notification history |

## Search and frecency

Search ranks by how well a row matches, in tiers 100 apart: the name starts with the query,
a word or the initials do ("rcc" for ROG Control Center), the label contains it, the second
column contains it, the label's letters appear in order. On top comes frecency, the way z
ranks directories for `cd`: every use adds 1 to a row's rank, the score is rank times 4
within the hour, 2 within the day, 0.5 within the week and 0.25 after, and when the ranks
add up past 1000 they all shrink by 1% and the ones under 1 are dropped. The bonus is
`min(150, 40 * ln(1 + score))`, so use lifts a row past a better match by one tier and never
by two. With no query, Apps lists the most frecent first.

Recorded are apps and the static menu items. Panel rows are not, because their order already
means something (connected first, default device first). The store is
`usage.json` under `Quickshell.statePath()`, which is per config, so a test copy keeps its own.

## Notifications

`Notifications.qml` owns `org.freedesktop.Notifications` in place of mako. Popups sit top
right like mako's did, history keeps the last 50 as plain copies, and do not disturb holds
popups back (not critical ones) while history still records them. sway starts mako only
when `qs` is missing. mako's D-Bus activation file also claims the name, so on endling
`mako.service` is masked; without that, a notification sent while quickshell restarts
starts mako, which then keeps the name.

```bash
systemctl --user mask mako.service      # done on endling 2026-10-09
systemctl --user unmask mako.service    # to go back to mako
```

## Interactions

| Module | Left click | Right click | Scroll |
|---|---|---|---|
| Workspace | switch to it | | |
| Idle inhibitor | toggle | | |
| Volume | audio panel | mute | volume 5% |
| Backlight | | | brightness 5% |
| Bluetooth | bluetooth panel | | |
| Network | network panel | `kitty -e nmtui` | |
| CPU | `kitty -e btop` | | |
| Power profile | cycle | rog-control-center | |
| Battery | power panel | | |
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

To test a binding without touching your real keys, bind a spare combination to the `nop`
command at runtime and press it with wtype:

```bash
swaymsg 'bindsym Mod4+Ctrl+Shift+F12 nop qs menu toggle root'
wtype -M logo -M ctrl -M shift -k F12 -m shift -m ctrl -m logo
swaymsg 'unbindsym Mod4+Ctrl+Shift+F12'
```

Both the test instance and the running bar receive the event, so test a target the
running bar does not have yet, or accept both reacting. The copy also draws a second bar
under the real one; replacing `Bar {}` with `QtObject {}` in the copy's `shell.qml` avoids it.

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

**A new QML file needs a restart, not a reload.** Quickshell's hot reload picks up edits to
files it already knows, but a type added since it started stays unknown: after `Usage.qml`
arrived, the running shell logged `ReferenceError: Usage is not defined` and the menu's
lists came up empty. Run `~/.config/quickshell/launch.sh` after adding a file.

**A cancelled capture must not reach wl-copy.** `grim -g "$(slurp)" - | wl-copy` puts an
empty string on the clipboard when slurp is cancelled, wiping what was there. The menu's
capture items check slurp's exit status first (`MenuTree.js`). The sway config's `Print`
bindings still have the old pattern.

**A wrong Wi-Fi password can hang instead of failing.** NetworkManager asks a secret agent
for a new password and waits. kded6 (plasma-nm) is still such an agent here and opened its own
dialog, so `connectionFailed` never fired. `NetworkPanel` gives a join 20 s, then disconnects,
forgets the new profile and reconnects the previous network.

**A handler reading a binding can see the old value.** `Menu.qml`'s `onViewChanged` read
`current`, which is itself a binding on `view`. QML does not promise the binding has
re-evaluated before the handler runs, so the handler saw the previous menu and a panel
learned it was on screen one change late. It opened empty and filled on the second open.
Derive from the changed property itself (`topOf(view)`).

**`WifiNetwork.signalStrength` is 0 to 1.** Treated as a percentage it printed "1%" and
drew the weakest bar for a network nmcli put at 86.

**`Notification.expireTimeout` is milliseconds**, though typed as a double. `notify-send -t
3000` arrives as 3000.

**A surface that maps under a resting pointer gets a hover event.** The menu's selection
jumped to whatever row sat under the mouse. The first position event after the list resets
is ignored (`Menu.hover`), the same trick as Omarchy's `PointerMoveGate.qml`.

**sway strips quotes and backslashes from a binding's command before it reports it.**
`exec printf 'x\n' | ...` arrived without the newline. `nop qs` arguments therefore cannot
hold spaces.

**Hiding the bar must not unmap it.** The idle inhibitor belongs to the bar's surface and
ends with it, so a hidden bar is one transparent pixel with no exclusive zone.

**`I3.focusedMonitor` is null until someone asks for the monitor list.** Reading it is
not what populates it. `Workspaces` happens to trigger the sync by reading
`I3.workspaces`, so anything relying on the property works by accident as long as that
module exists; `shell.qml` calls `I3.refreshMonitors()` at startup so BigClock does not.
