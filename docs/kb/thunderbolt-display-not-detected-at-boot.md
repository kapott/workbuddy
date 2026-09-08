# Thunderbolt display is dead after a cold boot, works after replugging

## Context

Host `endling`, ASUS ROG Flow Z13 GZ302EAC, CachyOS, kernel `7.2.3-1-cachyos`. An LG
38WN95C ultrawide hangs off one of the two USB4 Type-C ports over Thunderbolt 3, and sway
drives it as `DP-5`.

The laptop was booted with the monitor already plugged in.

## Problem

The external panel never lit up, from firmware through to the sway session. Only `eDP-1`
was ever active. Unplugging and replugging the cable brought it up immediately.

The kernel saw part of the monitor and none of the rest. All DP connectors were down:

```
$ for c in /sys/class/drm/card1-DP-*; do echo "$(basename $c): $(cat $c/status)"; done
card1-DP-1: disconnected
...
card1-DP-7: disconnected
```

No Thunderbolt link had trained, and no peripheral router existed beyond the two host
routers:

```
$ cat /sys/bus/thunderbolt/devices/0-0/usb4_port2/link
none
$ ls /sys/bus/thunderbolt/devices/
0-0  1-0  domain0  domain1

$ boltctl list
 o LG Electronics 38WN95C
   |- status:        disconnected
```

But the monitor's own USB 2.0 hub had enumerated during early boot, hostname still
`cachyos`, so this is inside the initramfs:

```
sep 08 08:56:30 cachyos kernel: xhci_hcd 0000:c6:00.3: new USB bus registered, assigned bus number 5
sep 08 08:56:30 cachyos kernel: usb 5-1: SerialNumber: 68050849FD1A
sep 08 08:56:31 cachyos kernel: usb 5-1.4: Product: LG Monitor Controls
```

Fourteen seconds later, hostname now `endling`, so after switch-root, the Thunderbolt
driver finally appeared:

```
sep 08 08:56:44 endling kernel: ACPI: bus type thunderbolt registered
```

and then nothing. No `thunderbolt 0-N: new device found` for the rest of the boot. `boltd`
probed and timed out on every attempt:

```
sep 08 08:56:45 endling boltd[1232]: probing: started [1000]
sep 08 08:56:48 endling boltd[1232]: probing: timeout, done: [2015828] (2000000)
```

A replug produced the enumeration that boot never did:

```
sep 08 09:48:55 endling kernel: thunderbolt 0-2: new device found, vendor=0x1e device=0x1117
sep 08 09:48:55 endling kernel: thunderbolt 0-2: LG Electronics 38WN95C
sep 08 09:48:56 endling kernel: thunderbolt 0-0:2.1: new retimer found, vendor=0x1da0 device=0x8833
sep 08 09:48:56 endling kernel: amdgpu 0000:c4:00.0: [drm] DMUB HPD IRQ callback: link_index=6
```

## Solution

The driver handles a hotplug. It does not handle a device that was already attached when
the module loaded. Two things put it in that position.

The `thunderbolt` module is not in the initramfs, so `xhci` binds the USB4 ports about
fourteen seconds before any Thunderbolt driver exists. That is why the USB 2.0 tunnel
comes up and gives you `LG Monitor Controls` with no picture. `/etc/mkinitcpio.conf` has:

```
MODULES=()
```

And `thunderbolt.host_reset` defaults to `true`. On probe the driver resets the USB4 host
router to discard whatever topology the boot firmware built. A device sitting on the port
during that reset does not re-announce itself, so no hotplug event is ever generated and
nothing goes looking for it.

```bash
$ modinfo thunderbolt | grep host_reset
parm:           host_reset:reset USB4 host router (default: true) (bool)
```

The fix to try first is the module parameter, because it is one line and reverts cleanly.
This machine boots Limine, so the command line lives in `/etc/default/limine`. Append to
`KERNEL_CMDLINE[default]`:

```
thunderbolt.host_reset=0
```

```bash
sudo limine-update
sudo reboot        # with the monitor plugged in
```

Verify without touching the cable:

```bash
cat /sys/class/drm/card1-DP-5/status        # want: connected
journalctl -k -b | grep "thunderbolt 0-"    # want: new device found, at boot time
boltctl list                                # want: 38WN95C status: connected
```

If that alone is not enough, put the driver in the initramfs as well, so it is present
before the ports are bound rather than fourteen seconds after:

```bash
# /etc/mkinitcpio.conf
MODULES=(thunderbolt)
sudo mkinitcpio -P
```

Change one at a time. Doing both at once tells you nothing about which mattered.

Turning `host_reset` off is a trade, not a free win. The reset exists because
firmware-built topology confuses Linux's software connection manager, so the cost shows up
as stale tunnels or a misbehaving dock after a warm reboot. If that happens, the initramfs
route is the better of the two.

**Status: the diagnosis is confirmed from the logs above, the fix is not yet verified on
this host.** Update this file once it has survived a cold boot.

Hypotheses that turned out wrong along the way:

- **A charge-only or USB 2.0 only USB-C cable.** Wrong, and it was the first conclusion.
  The signature genuinely fits at first glance: PD negotiates, the monitor's `TUSB8041`
  hub enumerates at 480 Mbps, the SuperSpeed companion bus stays empty, no DP connector
  comes up. Every one of those is also what a driver that loaded too late looks like. The
  cable trains `link=tbt` on a replug, which settles it. Check `usb4_port*/link` before
  blaming a cable.
- **A dead or half-connected USB-C port.** Wrong. Both domains exist and both host routers
  are present at boot. The port is fine; nothing was driving it.
- **kanshi, sway output blocks, or the display scripts.** Wrong, and worth stating because
  it is where you look first when a monitor does not appear in a Wayland session. All the
  DRM connectors read `disconnected`. Nothing above the kernel had anything to act on.

Useful first commands for anything in this area:

```bash
for c in /sys/class/drm/card1-*/status; do echo "$c: $(cat $c)"; done
cat /sys/bus/thunderbolt/devices/*-0/usb4_port*/link
boltctl list
journalctl -k -b | grep -iE "thunderbolt|usb4"
lsusb -t                        # a monitor hub at 480M with an empty SS bus is a hint
```
