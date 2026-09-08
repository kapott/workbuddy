# Paste into a FreeRDP session does nothing under sway

## Context

`endling`, CachyOS, moved from a Plasma session to sway on 2026-09-07. The RDP
client is a self-built `sdl-freerdp3` (FreeRDP 3.31.1-dev0, `2447661fd`) in
`/usr/local/bin`, launched by the fish function `rwe` against an Azure Virtual
Desktop gateway. Copy in a Wayland app, focus the RDP window, press Ctrl+V, and
the remote side stays empty. The same client and the same command worked under
Plasma.

## Problem

Nothing fails loudly. No error in the client, no error on the remote side, and
the clipboard channel is on: `Virtual Desktop.rdpw` carries
`redirectclipboard:i:1`, and `sdl-freerdp3 /help` prints

```
Disable clipboard redirection: -clipboard
```

which is how FreeRDP spells an option that is enabled by default.

The client runs as an XWayland window, not a native Wayland one:

```console
$ swaymsg -t get_tree | grep -B2 -A2 FreeRDP
"name": "FreeRDP: <host>", "shell": "xwayland",
"window_properties": { "class": "com.freerdp.client.sdl3" }
```

That happens because SDL3 3.4.16 on this machine picks the x11 driver by
default, even with `WAYLAND_DISPLAY` set and with the wayland driver working
when asked for by name. A minimal SDL3 program prints `driver=x11` with no
`SDL_VIDEO_DRIVER` in the environment.

The two routes do not advertise the same clipboard formats. Through XWayland:

```
TIMESTAMP TARGETS TEXT UTF8_STRING TEXT STRING UTF8_STRING
```

Native Wayland, same clipboard content:

```
text/plain;charset=utf-8 text/plain TEXT UTF8_STRING STRING
```

`text/plain` and `text/plain;charset=utf-8` are gone on the XWayland side, and
those are the first two entries FreeRDP looks for. `client/SDL/SDL3/sdl_clip.cpp`
builds the cliprdr format list from whatever mime types SDL reports in
`SDL_EVENT_CLIPBOARD_UPDATE` (`handleEvent`), then asks SDL for the data by mime
name (`getCurrentTextMime`, `sdl_clip.cpp:626`).

## Solution

Run the client on the Wayland driver:

```fish
SDL_VIDEO_DRIVER=wayland rwe
```

Paste works immediately. The setting now lives inside the `rwe` and `rwe-debug`
fish functions as `set -lx SDL_VIDEO_DRIVER wayland`, so it applies to that
client and to nothing else. Setting it globally would push every SDL3
application onto the Wayland backend, games included, which is a larger bet than
this problem justifies.

Note that `env` cannot do this, because `rwe` is a fish function rather than a
binary:

```console
$ env SDL_VIDEO_DRIVER=wayland rwe
env: 'rwe': No such file or directory
```

Fish applies its own `VAR=value command` prefix to functions as well, verified on
fish 4.9.2.

Check which route the client actually took:

```fish
swaymsg -t get_tree | grep -A2 FreeRDP | grep shell
```

`xdg_shell` is native Wayland, `xwayland` means the variable never arrived.

### Hypotheses that were wrong

- **sway does not bridge the clipboard to XWayland.** It does. With `wl-copy`
  holding the selection, a raw X11 selection conversion from an unfocused X
  client returned the text for `UTF8_STRING`, `STRING` and `TEXT` alike. The
  bridge is fine, and the first conversion attempt that failed was a race
  against `wl-copy` not yet owning the selection.
- **The sdl3 upgrade broke reading.** `sdl3` went `3.4.14-1.1 -> 3.4.16-1.1` on
  2026-09-07 at 22:12, hours after sway was installed at 12:12, which made it a
  good suspect. A minimal SDL3 probe with a mapped and focused window read the
  Wayland clipboard correctly under both drivers, so the read path itself works.
- **Clipboard redirection is off, or the gateway forbids it.** Neither. It is on
  by default and the `.rdpw` asks for it explicitly.

One detail cost two rounds of probing and is worth knowing: an SDL window that is
hidden, unmapped or unfocused receives no `SDL_EVENT_CLIPBOARD_UPDATE` at all,
under either driver. That is ordinary Wayland behaviour, not the bug, but it
makes a probe look broken when it is only unfocused.
