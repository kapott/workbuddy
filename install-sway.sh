#!/usr/bin/env bash
#
# Install the sway desktop stack and let chezmoi place this repo's sway-related
# configuration, without touching the rest of the dotfiles.
#
# Why this exists next to the chezmoi source instead of inside it: a bare
# `chezmoi apply` would also overwrite .bashrc, .zshrc, .gitconfig and the kitty
# config on a machine that is currently running Plasma. Naming the targets keeps
# the blast radius to ~/.config/{sway,waybar,mako,wofi,swaylock,kanshi} and one
# portal file, and chezmoi still renders the templates with this host's branch.
#
# It installs alongside the existing desktop. Nothing about the Plasma session
# changes; sway shows up as an extra entry in the login manager.

set -euo pipefail

usage() {
    cat <<'USAGE'
Install the sway desktop stack on an Arch-family machine, alongside whatever
desktop is already there.

  ./install-sway.sh                install packages and configuration
  ./install-sway.sh --dry-run      print what would happen, change nothing
  ./install-sway.sh --no-aur       skip wvkbd and autotiling
  ./install-sway.sh --config-only  skip package installation
  ./install-sway.sh --help         this text

Existing ~/.config directories for sway, waybar, mako, wofi, swaylock and
kanshi are moved aside to <name>.<timestamp>.bak before chezmoi writes.
USAGE
}

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SRC="$REPO/chezmoi"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

DRY=0
AUR=1
CONFIG_ONLY=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY=1 ;;
        --no-aur)      AUR=0 ;;
        --config-only) CONFIG_ONLY=1 ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "unknown option: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

say() { printf '\n== %s\n' "$*"; }
run() {
    if [ "$DRY" = 1 ]; then
        printf '  would run: %s\n' "$*"
    else
        "$@"
    fi
}

# Rendered from chezmoi/.chezmoidata/packages.toml, the same list the
# run_once_before_00-install-packages script uses on a fresh machine.
pkglist() {
    chezmoi execute-template --source "$SRC" \
        "{{ range concat $* }}{{ . }}
{{ end }}"
}

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "chezmoi is required, both for the package list and to render the configs." >&2
    exit 1
fi

if [ "$CONFIG_ONLY" = 0 ]; then
    if ! command -v pacman >/dev/null 2>&1; then
        echo "This script targets Arch-family systems (pacman)." >&2
        exit 1
    fi

    mapfile -t PKGS < <(pkglist '.packages.arch.core .packages.arch.tools .packages.arch.desktop')
    mapfile -t PKGS_AUR < <(pkglist '.packages.arch.aur')

    say "Installing packages from the repositories"
    run sudo pacman -S --needed "${PKGS[@]}"

    if [ "$AUR" = 1 ]; then
        if command -v paru >/dev/null 2>&1; then
            say "Installing AUR packages"
            run paru -S --needed "${PKGS_AUR[@]}"
        else
            echo "paru not found, skipping AUR packages: ${PKGS_AUR[*]}" >&2
        fi
    fi
fi

# Directories this repo owns outright, so moving an existing one aside is safe.
OWNED=(sway waybar mako wofi swaylock kanshi)

say "Backing up any configuration already there"
for dir in "${OWNED[@]}"; do
    [ -e "$DEST/$dir" ] || continue
    run mv "$DEST/$dir" "$DEST/$dir.$STAMP.bak"
done

# The portal preferences file shares ~/.config/xdg-desktop-portal with whatever
# else put a config there, so it is applied but never backed up wholesale.
TARGETS=()
for dir in "${OWNED[@]}"; do TARGETS+=("$DEST/$dir"); done
TARGETS+=("$DEST/xdg-desktop-portal/sway-portals.conf")

say "Applying the sway configuration with chezmoi"
run mkdir -p "$DEST"
if [ "$DRY" = 1 ]; then
    chezmoi apply --source "$SRC" --destination "$HOME" --dry-run -v "${TARGETS[@]}"
else
    chezmoi apply --source "$SRC" --destination "$HOME" -v "${TARGETS[@]}"
fi

say "Creating the screenshot directory"
run mkdir -p "$HOME/Pictures/Screenshots"

if [ "$DRY" = 0 ] && command -v sway >/dev/null 2>&1; then
    say "Validating the generated sway config"
    if sway --validate --config "$DEST/sway/config"; then
        echo "config parses"
    else
        echo "sway rejected the config, see the errors above" >&2
        exit 1
    fi
fi

cat <<'DONE'

== Next

Log out and pick "Sway" in the login manager. Plasma stays where it is.

First things to check once you are in:
  swaymsg -t get_outputs      names and modes actually applied
  swaymsg -t get_inputs       identifiers, if a device needs its own block
  Mod+Return                  kitty
  Mod+Space                   wofi

If the screen stays black, switch to a TTY with Ctrl+Alt+F3 and read
~/.local/share/sway/ or `journalctl --user -b -u sway` for the parse error.
DONE
