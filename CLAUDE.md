# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles and workstation provisioning for Linux, macOS and NixOS. It holds three
independent provisioning systems that each own a different slice of the machine. Nothing chains them
together, so a change in one does not reach the others.

1. `chezmoi/` is the current system. It manages the dotfiles themselves plus the install scripts that
   put packages, mise, oh-my-zsh, Vundle, fonts and the login shell on the machine.
2. `chezmoi/nixos/` is a NixOS flake for one host (`legion`, a Lenovo Legion 16ACH6H). Chezmoi
   explicitly ignores it (`.chezmoiignore`); `nixos-rebuild` applies it.
3. `roles/` plus `local*.yml` is the older Ansible layer, kept for reference. It symlinks dotfiles
   out of `roles/<tool>/files/` instead of rendering them.

Layers 1 and 3 both ship a bash config and they have drifted apart. `roles/bash/files/bashrc.d/` has
`22-pomodoro` and `99-z` that `chezmoi/dot_bashrc.d/` lacks, and six of the seven shared files differ.
The chezmoi copy is the one that gets worked on, so the gap only widens.
When editing shell config, decide which layer is in play and say so; do not assume the two are
copies of each other.

## Shells

Three shells are managed and they are not interchangeable in how they are built. Bash gets
`dot_bashrc` plus the numbered fragments in `dot_bashrc.d/`. Zsh gets `dot_zshrc.tmpl`, which sources
oh-my-zsh and then reaches back into `~/.bashrc.d/` for the aliases and functions. Fish cannot source
either, so `private_dot_config/private_fish/` carries its own translation: `conf.d/*.fish` for env,
aliases and settings, `functions/*.fish` for the autoloaded helpers.

Fish is the login shell on `endling` (`getent passwd`), so a change that only lands in bash and zsh
reaches nothing the user actually types into. When you add an alias or function, add it in both
places or say plainly that you did not.

Which shell that is comes from a `chezmoi init` prompt, and all three are installed either way, so
no shell is "the" one in the source. `run_once_after_20-set-login-shell.sh.tmpl` runs the `chsh`. It
refuses rather than fails when it cannot (no password prompt available, shell missing, shell not in
`/etc/shells`), and it compares the current and wanted shell through `readlink -f`, because
`command -v fish` answers `/usr/bin/fish` where passwd may hold `/bin/fish`.

The fish config deliberately does not source `/usr/share/cachyos-fish-config/cachyos-config.fish`.
The parts worth having were copied into `conf.d/`; `done.fish` is the one piece still sourced by
path. Two CachyOS aliases were left out on purpose and should stay out: `apt`/`apt-get` mapped onto
`man pacman`, which shadows the real binaries inside a Debian container, and `wget='wget -c'`.

The prompt is written twice and has to stay written twice: `dot_bashrc.d/01-prompt` for bash
and `private_dot_config/private_fish/functions/fish_prompt.fish` for fish. Same shape (time,
`user@host`, cwd, git branch, then the exit status on its own line) and the same four colours,
256-colour indices in bash and the matching hex in fish because `set_color` takes no index. Change
one and change the other. zsh uses powerlevel10k instead and matches neither.

`01-prompt` appends to `PROMPT_COMMAND` rather than assigning it. Arch's `/etc/bash.bashrc` fills
that variable as an array to write the window title, and mise adds its own entry; a plain assignment
drops both silently.

CachyOS ships no bash config, so there is nothing to borrow there. `/etc/skel/.bashrc` is the stock
ten-line Arch file. The two shells the distro does dress up are zsh, through `cachyos-zsh-config`,
which brings powerlevel10k, syntax highlighting and autosuggestions, and fish, through
`cachyos-fish-config`, which brings the eza aliases and `done.fish` and no prompt at all. Pieces of
both were copied into the bash and zsh configs here, by path and each behind a file test, the way
the fish config already treats them. Sourcing either package wholesale is the thing to avoid, and
the reason is the one in the `cachyos-config.fish` paragraph above.

`fish_add_path` in `conf.d/00-env.fish` uses `-g`. Without the flag it writes to the universal
`fish_user_paths`, which already exists on this machine, so every shell start would persist paths
into `~/.config/fish/fish_variables`. Git owns the path list, not that file.

## Commands

Chezmoi (the path that matters day to day):

```bash
chezmoi init --source ~/Documents/git/personal/workbuddy/chezmoi   # first time
chezmoi diff                     # preview every pending change
chezmoi apply -v                 # apply dotfiles and run pending scripts
chezmoi apply -v ~/.zshrc        # apply a single target
chezmoi execute-template < chezmoi/dot_gitconfig.tmpl   # render one template to stdout
chezmoi doctor
```

There is no test suite and no linter. Verification is running the thing:

```bash
chezmoi diff                     # the real check on a template edit
mise doctor
vim +PluginInstall +qall
fc-list | grep -i hack
```

NixOS (`legion` only):

```bash
sudo ln -sf ~/Documents/git/personal/workbuddy/chezmoi/nixos /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#legion
sudo nixos-rebuild build --flake /etc/nixos#legion    # check it evaluates, change nothing
```

Ansible (legacy):

```bash
ansible-galaxy collection install community.general
ansible-playbook local-tools.yml -i ./inventories/localhost --ask-become-pass
ansible-playbook local-tools.yml -i ./inventories/localhost --tags vim,tmux --ask-become-pass
ansible-playbook local-i3wm.yml -i ./inventories/localhost --ask-become-pass
```

## Chezmoi naming rules

Filenames in `chezmoi/` are the mechanism, not decoration. Get a prefix wrong and the file lands in
the wrong place with the wrong mode.

- `dot_foo` becomes `~/.foo`; `private_dot_config/` becomes `~/.config/` with mode 0600.
- `.tmpl` makes chezmoi render Go template syntax. `.chezmoi.toml.tmpl` prompts once for `name`,
  `email` and `shell`. The first two are what `dot_gitconfig.tmpl` interpolates; `shell` is bash,
  zsh or fish and reaches `run_once_after_20-set-login-shell.sh.tmpl`. Any new prompt goes there.
  The prompt functions exist only during `chezmoi init`, so `chezmoi execute-template` on a file
  that calls one fails with "function not defined"; render it against a config file instead, with
  `--config <path to a chezmoi.toml>`.
- OS branching inside a template is `{{ if eq .chezmoi.os "linux" }}`. Whole files are excluded per
  OS in `.chezmoiignore` instead; that is where the Wayland configs get hidden on macOS.

## Chezmoi script ordering

`chezmoi/.chezmoiscripts/` runs on `apply`, ordered by `before`/`after` and then by the numeric
prefix. The current order is packages, mise, oh-my-zsh (all `before`), then Vundle, fonts and the
login shell (`after`).

`run_once_*` scripts run once per machine, keyed on a hash of the script. Editing one makes it run
again everywhere it has already run, so treat an edit as a re-run, not a patch.

`run_onchange_after_mise-install.sh.tmpl` is the exception and is keyed deliberately: its header
carries `{{ include "private_dot_config/private_mise/config.toml" | sha256sum }}`, so editing that
file re-triggers `mise install`. Keep that line if you touch the script. `include` resolves against
the source directory, so rendering it by hand needs `chezmoi execute-template --source chezmoi/`.

`install-sway.sh` installs packages the same way and for the same reason, through its own
`missing_packages`. The two are separate scripts with one rule between them, so a change to how
packages get installed belongs in both.

`run_once_before_00-install-packages.sh.tmpl` branches on `$ID` from `/etc/os-release` and installs
the desktop set (sway, quickshell, wofi, mako, kitty, grim, slurp, wl-clipboard) only when a display
session is detected. New distro support goes in that `case`.

Its Arch branch runs a full `pacman -Syu` only when none of the wanted packages is installed, which
is what a machine being provisioned from nothing looks like. Otherwise it installs the missing names
and nothing else. Both halves of that matter. `-Syu` on a machine in use upgrades the kernel on a day
its owner did not pick, and `--needed` over the whole list is not a safe substitute, because it
compares against the sync database and CachyOS versions sit above Arch's, so pacman reads the list as
a downgrade request and refuses. See
[`docs/kb/pacman-needed-wants-to-downgrade-cachyos-packages.md`](docs/kb/pacman-needed-wants-to-downgrade-cachyos-packages.md).

## NixOS flake

`flake.nix` composes four things for the `legion` host: the `nixos-hardware` module for the machine,
`hosts/legion/default.nix`, the shared `modules/`, and Home Manager for user `therder` from
`home/default.nix`. System-wide packages and services belong in `modules/` or the host file; user
packages belong in `home/default.nix`.

`modules/nvidia.nix` hardcodes PRIME bus IDs (`amdgpuBusId = "PCI:6:0:0"`, `nvidiaBusId =
"PCI:1:0:0"`). Those are per-machine and `lspci | grep -E 'VGA|3D'` is how you get the real ones.
`hosts/legion/hardware-configuration.nix` is likewise machine-specific and generated, not authored.

Chezmoi does not apply this tree, so a change here is inert until someone runs `nixos-rebuild`.

## Ansible layer

Each role's `tasks/main.yml` starts with the same dispatch: `import_tasks` for `arch.yml`,
`macos.yml`, `debian.yml`, `redhat.yml` guarded on `ansible_os_family`. Follow that shape for a new
role rather than branching inside one file. Not every role has all four; the missing ones are simply
unsupported there.

Roles symlink into `$HOME` from `{{ repo_home }}` (the playbook dir) or `{{ role_path }}`, backing up
an existing file to `.bak` first. The symlinks point back into this working tree, so moving or
renaming the repo breaks an already-provisioned machine.

`inventories/localhost` defines the `local` group. `local.yml` targets `hosts: localhost` while
`local-tools.yml` and `local-i3wm.yml` target `hosts: local`, so `local.yml` runs without the
inventory and the other two need `-i ./inventories/localhost`.

`group_vars/local` carries the git identity for this layer, separate from the chezmoi prompt data.
The two can disagree.

## Sway session environment

`session-env.sh` publishes `DISPLAY`, `WAYLAND_DISPLAY`, `SWAYSOCK` and
`XDG_CURRENT_DESKTOP` to the systemd user manager and to D-Bus activation, but
only after checking that no other compositor is holding the display. That check
is the whole point of the file, so do not simplify it away.

The systemd user manager is per user, not per session. An unguarded
`systemctl --user import-environment WAYLAND_DISPLAY ...` from a sway started
inside a running Plasma session overwrites Plasma's values for every unit, and
quitting sway does not restore them. Plasma then launches apps as systemd user
units (`KDE_APPLICATIONS_AS_SCOPE=1`) into a dead display: spectacle aborts with
"Failed to create wl_display" and dumps core. Apps already running, or started
from a terminal, keep working because they inherit a good environment from their
parent, so it reads as one broken app rather than a broken session.

The liveness test is an `flock -n` on `$XDG_RUNTIME_DIR/<display>.lock`. A
compositor holds that lock for as long as it runs, so a lock we can take means
the socket is a stale leftover and importing is safe.

For the same reason the config does not `include /etc/sway/config.d/*`. The one
file Arch ships there, `50-systemd-user.conf`, performs exactly that unguarded
import. Adding the include back reintroduces the bug.

`autorotate.sh` ties its own lifetime to `$SWAYSOCK` and reaps `monitor-sensor`
through a trap. sway does not reliably reap what `exec` starts, and a blocking
read on a sensor that may be silent for hours leaves orphans behind; that
happened during testing before the timeout was added.

## The bar is quickshell, and it is QML

`chezmoi/private_dot_config/private_quickshell/` is the bar. It is a QtQuick shell:
one `.qml` file per module, all flat in that directory because QML resolves types from the
directory a file sits in. `chezmoi/private_dot_config/private_quickshell/README.md` is the
reference for what each file does and what bit during the port; read it before editing a
module.

waybar is the fallback, not dead weight. `private_dot_config/private_sway/executable_bar.sh`
is what `exec_always` runs: quickshell when `qs` is on `$PATH`, waybar otherwise, and it
kills the loser. Debian, Ubuntu and Fedora package waybar and not quickshell, which is the
whole reason `private_waybar/` is still here. The choice is made at start rather than in a
chezmoi template because chezmoi reads `.chezmoiignore` before `run_once_before_*` installs
anything, so a `lookPath` branch is one apply behind on a fresh machine.

Three things that decide whether a change works:

- `Host.qml.tmpl` is the only templated file. Per-machine hardware paths go there, not into
  a module. It is also why `qs -p` straight from the source directory fails: `Host.qml`
  only exists after chezmoi renders it.
- Icons live in `Glyph.qml` as codepoints. Check the glyph *name* against the font, not
  just that the codepoint resolves; two values in the first draft were present and wrong.
- `power-profile.sh` and the `PowerProfile` module are one unit. The script writes
  `$XDG_RUNTIME_DIR/power-profile` on every change and the module watches that file, which
  is how the ROG fan key repaints the bar. Change the format on one side and change it on
  the other.

## Desktop entry overrides live in `dot_local/`

`chezmoi/dot_local/share/applications/` shadows entries from
`/usr/share/applications/`. XDG reads `$XDG_DATA_HOME` first, so a file with the
same name wins for wofi, the tray and the URL handlers alike. Copy the packaged
entry and change only the line you mean to change; anything you drop (MimeType,
StartupWMClass) is lost, not inherited.

`dot_local/bin/executable_signal-desktop` is the one such wrapper today. Signal
records in `~/.config/Signal/config.json` which safeStorage backend encrypted its
database key, Electron re-derives that backend from `XDG_CURRENT_DESKTOP` at
every start, and the two disagree the moment you boot a different compositor. The
wrapper reads the recorded value and passes `--password-store=`. Note the two
spellings: Electron reports `basic_text` and `gnome_libsecret`, the flag takes
`basic` and `gnome-libsecret`. See
[`docs/kb/signal-refuses-to-start-after-switching-desktop.md`](docs/kb/signal-refuses-to-start-after-switching-desktop.md).

These paths are not `private_`, unlike `private_dot_config/`. `~/.local/bin` and
`~/.local/share/applications` already exist at 0755 on a provisioned machine and
chezmoi would chmod them to 0700.

## Wayland migration

`chezmoi/i3-to-sway.md` is the mapping table for the X11 to Wayland move (i3 to sway, polybar to
quickshell, rofi to wofi, dunst to mako, feh to swaybg, flameshot to grim plus slurp). The i3 and polybar
roles under `roles/` are the superseded side of that table. Window matching changed from `class` to
`app_id`, which is the thing that silently breaks a ported rule.

## Sway bindings and their README are one unit

`chezmoi/private_dot_config/private_sway/README.md` is the cheatsheet for every binding in
`config.tmpl`, written by hand. Edit one and edit the other in the same change, in either
direction:

- a binding added, removed or remapped in `config.tmpl` gets its row in the README updated;
- a row changed in the README is a request to change the binding, so make `config.tmpl`
  match it.

`config.tmpl` is what sway runs, so it wins on any conflict that is not clearly a typo. Say
which side you changed.

Host-specific bindings live inside the `{{ if eq .chezmoi.hostname "endling" }}` blocks and
are marked **Z13** in the README. Keep that marking; a reader on another host needs to know
the key does nothing there.

Check for a duplicate before reloading. sway prints `Overwriting binding ...` and keeps only
the last one, which is how `$mod+Ctrl+$right` (that is `Mod+Ctrl+l`) silently ate the lock
binding:

```bash
chezmoi execute-template --source chezmoi/ < chezmoi/private_dot_config/private_sway/config.tmpl > /tmp/sway-check
sway --validate -c /tmp/sway-check
```

The README is not deployed. `.chezmoiignore` needs `**/README.md` for that, since a bare
`README.md` only matches the repo root.
