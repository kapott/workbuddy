#!/usr/bin/env bash
#
# Install the sway desktop stack and let chezmoi place this repo's sway-related
# configuration, without touching the rest of the dotfiles.
#
# Why this exists next to the chezmoi source instead of inside it: a bare
# `chezmoi apply` would also overwrite .bashrc, .zshrc, .gitconfig and the kitty
# config on a machine that is currently running Plasma. Naming the targets keeps
# the blast radius to ~/.config/{sway,quickshell,waybar,mako,wofi,swaylock,kanshi}
# and one portal file, and chezmoi still renders the templates with this host's
# branch.
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

Existing ~/.config directories for sway, quickshell, waybar, mako, wofi,
swaylock and kanshi are moved aside to <name>.<timestamp>.bak before chezmoi
writes.
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
# waybar is in the list because ~/.config/sway/bar.sh falls back to it when
# quickshell is missing, so its config ships on every machine even where nothing
# starts it.
OWNED=(sway quickshell waybar mako wofi swaylock kanshi)

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

# --force because the backup step above already moved every target aside, so
# there is nothing left for chezmoi's overwrite guard to protect. Without it
# chezmoi asks "<target> has changed since chezmoi last wrote it?" and, with no
# TTY, dies on `could not open a new TTY`. That leaves the directories renamed to
# .bak and nothing written in their place, which looks like the script wiped
# ~/.config.
say "Applying the sway configuration with chezmoi"
run mkdir -p "$DEST"
if [ "$DRY" = 1 ]; then
    chezmoi apply --source "$SRC" --destination "$HOME" --dry-run -v "${TARGETS[@]}"
else
    chezmoi apply --source "$SRC" --destination "$HOME" --force -v "${TARGETS[@]}"
fi

say "Creating the screenshot directory"
run mkdir -p "$HOME/Pictures/Screenshots"

# Report on the secret store rather than touching it. A vault holds browser
# safe-storage keys, tokens and saved passwords, so guessing wrong here loses
# real data. All this does is say what is on disk and whether the login unlock
# can work, and leave the decisions to a human.
say "Checking for an existing secret store"
secret_store_report() {
    local data="${XDG_DATA_HOME:-$HOME/.local/share}"
    local -a kwl keyring

    # nullglob rather than counting `ls` output. Under `set -euo pipefail` an
    # assignment from `ls missing/* | wc -l` takes the pipeline's status, which is
    # ls failing, and the script ends here without printing anything. That is what
    # it did on a machine with a kwallet and no gnome-keyring.
    shopt -s nullglob
    kwl=("$data"/kwalletd/*.kwl)
    keyring=("$data"/keyrings/*.keyring)
    shopt -u nullglob

    if [ "${#kwl[@]}" -gt 0 ]; then
        echo "  found a KDE wallet: $data/kwalletd"
    fi
    if [ "${#keyring[@]}" -gt 0 ]; then
        echo "  found a gnome-keyring store: $data/keyrings"
    fi

    if [ "${#kwl[@]}" -gt 0 ] && [ "${#keyring[@]}" -gt 0 ]; then
        cat <<'WARN'
  Both stores exist. Only one process can own org.freedesktop.secrets, so
  whichever starts first wins and the other one's contents become invisible.
  Decide which to keep before logging into sway, and migrate rather than
  running both.
WARN
        return
    fi

    if [ "${#kwl[@]}" = 0 ] && [ "${#keyring[@]}" = 0 ]; then
        echo "  no existing store. kwallet will create one on first use, and"
        echo "  its ksecretd serves org.freedesktop.secrets for every libsecret client."
        return
    fi

    # A wallet exists, so the only question left is whether it opens by itself.
    if [ "${#kwl[@]}" -gt 0 ]; then
        if [ ! -e /usr/lib/security/pam_kwallet5.so ]; then
            echo "  kwallet-pam is not installed, so the wallet will ask for a password"
            echo "  on every login. Install it to hand the login password over instead."
        elif ! grep -rq pam_kwallet5 /usr/lib/pam.d/ /etc/pam.d/ 2>/dev/null; then
            echo "  pam_kwallet5.so is installed but no PAM stack calls it. The login"
            echo "  manager will not hand the password over; expect a prompt per login."
        else
            echo "  pam_kwallet5 is wired into a PAM stack, and the sway config runs"
            echo "  pam_kwallet_init to finish the handover. The wallet should open on login."
        fi
        echo "  This only works when the wallet password equals the login password."
    fi
}
secret_store_report

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
