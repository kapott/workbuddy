# KWallet asks for a password on every login under sway

## Context

Host `endling`, sway started from `plasmalogin` (`plasma-login-manager`), alongside an
existing Plasma installation. `kwallet 6.29.0`, `kwallet-pam 6.7.4`.

Signal was the app that surfaced it, but this hits everything that stores a secret. The
wallet holds Chrome, Chromium and VSCodium safe-storage keys, `Signal Keys/Signal Safe
Storage`, Nextcloud credentials, two GitHub tokens under `Secret Service/`, and SMB
passwords.

## Problem

Starting Signal popped a KWallet password prompt, on every launch. The same happened for
anything else asking for a secret. Under Plasma it had never prompted.

The PAM side looked correct. `pam_kwallet5` is in the login stack:

```
/usr/lib/pam.d/plasmalogin:8:-auth       optional    pam_kwallet5.so
/usr/lib/pam.d/plasmalogin:18:-session   optional    pam_kwallet5.so         auto_start
```

It ran, and it started the daemon with the login password on file descriptors 8 and 9:

```
sep 08 08:57:03 endling plasmalogin-helper[2051]: pam_kwallet5: final socket path: /run/user/1000/kwallet5.socket

$ ps -o pid,ppid,args -p 2053
    PID    PPID COMMAND
   2053       1 /usr/bin/ksecretd --pam-login 8 9
$ ls -la /run/user/1000/kwallet5.socket
srwxr-xr-x 1 therder therder 0  8 sep 08:57 /run/user/1000/kwallet5.socket
```

The daemon was running two hours later and owned no D-Bus name at all:

```
$ busctl --user list --acquired | grep -iE "secret|wallet"
  (nothing)
$ busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus GetNameOwner s org.freedesktop.secrets
Call failed: The name does not have an owner
```

Asking for a secret activated a *second*, empty daemon, which is what put the prompt on
screen:

```
$ busctl --user call org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet isOpen s kdewallet
b false
$ pgrep -af "ksecretd|kwalletd6"
2053   /usr/bin/ksecretd --pam-login 8 9      # holds the password, serves nobody
155546 /usr/bin/kwalletd6                     # just activated, wallet closed
155553 /usr/bin/ksecretd                      # just activated, owns org.freedesktop.secrets
```

## Solution

The PAM handover is in two halves and sway only gets the first one for free.

`pam_kwallet5.so` starts `ksecretd --pam-login` and leaves a socket at
`$XDG_RUNTIME_DIR/kwallet5.socket`. The daemon then waits. It opens nothing and registers
nothing until `/usr/lib/pam_kwallet_init` connects to that socket.

Upstream ships that second half two ways, and sway runs neither:

```
/etc/xdg/autostart/pam_kwallet_init.desktop        # XDG autostart, sway has no autostart handling
/usr/lib/systemd/user/plasma-kwallet-pam.service   # static, PartOf=graphical-session.target
```

`plasma-kwallet-pam.service` is `static`, so it has no `[Install]` section and nothing
pulls it in, and it belongs to a target a sway session never starts. Plasma runs the
autostart entry, which is why the same machine behaves under Plasma and not under sway.

Running the missing step by hand was enough. The daemon that had the password went from
owning nothing to owning the Secret Service name:

```bash
$ /usr/lib/pam_kwallet_init
$ busctl --user list --acquired | grep org.freedesktop.secrets
org.freedesktop.secrets    2053 ksecretd    therder :1.233    session-2.scope
```

So the fix is one line in the sway config, next to the other `exec` entries:

```
exec test -S "$XDG_RUNTIME_DIR/kwallet5.socket" && /usr/lib/pam_kwallet_init
```

The `test -S` guard matters. On a TTY login no PAM module creates that socket, and
running `pam_kwallet_init` against nothing is a pointless failure in the sway log.

Two conditions on this working at all:

- The wallet password must equal the login password. PAM only forwards the one you typed,
  so a wallet with its own password will always prompt.
- Only PAM stacks that call `pam_kwallet5` hand a password over. `/etc/pam.d/login` does
  not, so starting sway from a TTY gets no unlock. Adding it there is possible but it is a
  root-owned file outside chezmoi's reach, and a broken PAM stack locks you out.

Hypotheses that turned out wrong along the way:

- **kwallet is KDE-only, so a sway session needs gnome-keyring instead.** Wrong, and
  acting on it would have made things worse. `ksecretd` owns `org.freedesktop.secrets`,
  the cross-desktop Secret Service name, so every libsecret client already talks to the
  same wallet. Installing gnome-keyring alongside gives two processes racing for one bus
  name and splits secrets across two files.
- **The PAM configuration is missing or wrong.** Wrong. Both the `auth` and `session`
  lines are present in `/usr/lib/pam.d/plasmalogin` and both fire. Nothing in `/etc/pam.d`
  mentions kwallet, which looks alarming and is not the problem; the stack lives in
  `/usr/lib/pam.d`.
- **`XDG_CURRENT_DESKTOP=sway` makes Electron apps pick the wrong backend.** Wrong here.
  Signal had already pinned itself in `~/.config/Signal/config.json` with
  `"safeStorageBackend": "kwallet6"`, so autodetection never ran. Do not edit that value
  to work around a prompt: the key is encrypted under the current backend and changing it
  risks having to re-link the device.

## Notes

`kwallet6` in that Signal config is the legacy `org.kde.kwalletd6` name, served by
`/usr/bin/kwalletd6`, a different binary from `ksecretd`. PAM only ever passes the
password to `ksecretd`, so an app pinned to `kwallet6` may still prompt even with the fix
in place. Confirm with a fresh login before assuming either way.

Useful first commands in this area:

```bash
busctl --user list --acquired | grep -iE "secret|wallet"   # who is actually serving
pgrep -af "ksecretd|kwalletd6"                             # more than one is the symptom
ls -la "$XDG_RUNTIME_DIR"/kwallet5.socket                  # did PAM run at all
grep -rn kwallet /usr/lib/pam.d/ /etc/pam.d/               # which stack calls the module
ls ~/.local/share/kwalletd/ ~/.local/share/keyrings/       # which stores exist on disk
```
