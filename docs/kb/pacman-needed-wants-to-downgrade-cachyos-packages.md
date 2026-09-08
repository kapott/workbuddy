# pacman --needed wants to downgrade CachyOS packages

## Context

`endling`, CachyOS. Reworking `chezmoi/.chezmoiscripts/run_once_before_00-install-packages.sh.tmpl`
so it stops running `pacman -Syu --noconfirm` on a machine already in use. The replacement was
`pacman -S --needed` over the same package list, on the assumption that `--needed` skips whatever is
already installed.

## Problem

A dry run over the 41 names in `.chezmoidata/packages.toml`, 40 of them installed:

```
$ pacman -S --needed --print git vim tmux zsh fish curl sway ... pipewire wireplumber
:: installing pipewire (1:1.6.8-1) breaks dependency 'pipewire=1:1.6.8-1.2' required by pipewire-alsa
:: installing libpipewire (1:1.6.8-1) breaks dependency 'libpipewire=1:1.6.8-1.2' required by pipewire-audio
:: installing pipewire (1:1.6.8-1) breaks dependency 'pipewire=1:1.6.8-1.2' required by pipewire-pulse
```

`--needed` skips a package only when the installed version equals the one in the sync database.
CachyOS rebuilds a large part of the Arch tree with its own pkgrel, so the installed `pipewire` is
`1:1.6.8-1.2` while `extra` offers `1:1.6.8-1`. Different version, so `--needed` does not skip it, and
what pacman then plans is a downgrade. `pipewire-alsa`, `pipewire-audio` and `pipewire-pulse` pin the
exact version they were built against, so the transaction fails and nothing installs, including the
one package that really was missing.

A hypothesis that was wrong: **adding `-y` fixes it.** It makes it worse. `-Sy` without `u` refreshes
the sync database and then installs against it, which is a partial upgrade, and Arch does not support
those. The version skew is not staleness; it is the CachyOS repository having different pkgrels on
purpose.

## Solution

Ask which packages are absent and hand pacman only those. A name that is not installed cannot be
downgraded, so the whole class of conflict disappears:

```bash
missing_packages() {
    local package
    for package in "$@"; do
        pacman -Qq "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
    done
}

mapfile -t missing < <(missing_packages "${packages[@]}")
[ ${#missing[@]} -gt 0 ] && sudo pacman -S --needed --noconfirm "${missing[@]}"
```

`pacman -Qq a b c` cannot answer this. It returns one exit status for the whole set and says nothing
about which name was missing, so the loop asks once per package.

The same count decides whether a full upgrade is appropriate. Nothing from the list installed means
the machine is being provisioned from nothing, where `pacman -Syu` is right; anything else means the
machine is in use and the upgrade is its owner's call.
