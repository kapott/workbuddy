# Signal refuses to start after switching desktop

## Context

`endling`, CachyOS. Signal Desktop was installed and first run under a Plasma
session, then the machine moved to sway. Launching Signal from wofi
(`$mod+space`) showed an error about the password store; from a terminal it
printed the real reason and quit.

## Problem

```
Detected change in safeStorage backend, can't decrypt DB key (previous: kwallet6, current: basic_text)
2026-09-08 14:08:19.562: ERROR CORE sqlcipher_page_cipher: hmac check failed for pgno=1
2026-09-08 14:08:19.562: ERROR CORE sqlite3Codec: error decrypting page 1 data: 1
```

Signal encrypts its SQLCipher key with Electron's `safeStorage` and writes the
backend that did it into `~/.config/Signal/config.json`:

```json
{ "encryptedKey": "7631...", "safeStorageBackend": "kwallet6" }
```

Electron picks that backend from `XDG_CURRENT_DESKTOP` at every start. Under
Plasma it reads KDE and chooses kwallet6; under sway the variable is
`sway;wlroots`, no store matches, and Chromium falls back to `basic_text`, whose
key is a hardcoded string. The recorded backend and the running one disagree, so
the DB key never decrypts.

Two hypotheses that were wrong:

- **The wallet is locked or missing.** It is not. `busctl --user list` showed
  `ksecretd` holding `org.freedesktop.secrets` and `org.kde.kwalletd6` present as
  an activatable name, both unlocked by the pam_kwallet handover sway performs
  (see `kwallet-asks-for-a-password-on-every-login-under-sway.md`). Chromium
  simply never asked it.
- **The profile is corrupt and Signal needs relinking.** Nothing is damaged. The
  same profile opens with one flag.

## Solution

Pass the recorded backend explicitly instead of letting Electron guess:

```bash
signal-desktop --password-store=kwallet6
```

`--password-store=` overrides the `XDG_CURRENT_DESKTOP` sniffing, kwalletd6 is
D-Bus activatable and inherits the wallet PAM already opened, and Signal finds
the backend it expects.

To make that survive the next desktop switch without hardcoding kwallet6,
`chezmoi/dot_local/bin/executable_signal-desktop` reads `safeStorageBackend`
straight out of `config.json` and passes whatever it finds, falling back to
whatever secret service is on the bus when the profile is new.
`chezmoi/dot_local/share/applications/signal.desktop.tmpl` overrides the packaged
entry so wofi and the `sgnl://` handler use the wrapper too. Verify with:

```bash
chezmoi diff --source ~/Documents/git/personal/workbuddy/chezmoi
desktop-file-validate ~/.local/share/applications/signal.desktop
~/.local/bin/signal-desktop
```

The flag spelling is not the recorded spelling. Electron reports `basic_text` and
`gnome_libsecret`; the command line wants `basic` and `gnome-libsecret`. The
wrapper translates.
