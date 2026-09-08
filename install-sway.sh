#!/usr/bin/env bash
#
# Install the sway desktop stack and let chezmoi place this repo's sway-related
# configuration, without touching the rest of the dotfiles.
#
# Why this exists next to the chezmoi source instead of inside it: a bare
# `chezmoi apply` would also overwrite .bashrc, .zshrc, .gitconfig and the kitty
# config on a machine that is currently running Plasma. Naming the targets keeps
# the blast radius to the directories in CONFIG_OWNED_DIRS and one portal file,
# and chezmoi still renders the templates with this host's branch.
#
# It installs alongside the existing desktop. Nothing about the Plasma session
# changes; sway shows up as an extra entry in the login manager.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

# Directories this repo owns outright, so moving an existing one aside is safe.
# waybar is in the list because ~/.config/sway/bar.sh falls back to it when
# quickshell is missing, so its config ships on every machine even where nothing
# starts it.
readonly CONFIG_OWNED_DIRS=(sway quickshell waybar mako wofi swaylock kanshi)

# The portal preferences file shares ~/.config/xdg-desktop-portal with whatever
# else put a config there, so it is applied but never backed up wholesale.
readonly CONFIG_PORTAL_FILE="xdg-desktop-portal/sway-portals.conf"

# Rendered from chezmoi/.chezmoidata/packages.toml, the same list the
# run_once_before_00-install-packages script uses on a fresh machine.
readonly CONFIG_REPO_PACKAGE_GROUPS=".packages.arch.core .packages.arch.tools .packages.arch.desktop"
readonly CONFIG_AUR_PACKAGE_GROUPS=".packages.arch.aur"

readonly CONFIG_SCREENSHOT_DIR="Pictures/Screenshots"

readonly CONFIG_KWALLET_PAM_MODULE="/usr/lib/security/pam_kwallet5.so"
readonly CONFIG_PAM_DIRS=(/usr/lib/pam.d /etc/pam.d)

# ---------------------------------------------------------------------------
# The story
# ---------------------------------------------------------------------------

main() {
    parse_options "$@"

    if [ "${OPTIONS[help]}" = yes ]; then
        usage
        return 0
    fi

    require_command chezmoi "chezmoi is required, both for the package list and to render the configs."

    local dry="${OPTIONS[dry_run]}"
    local source_dir dest stamp
    source_dir="$(chezmoi_source_dir)"
    dest="$(config_home)"
    stamp="$(timestamp)"

    if [ "${OPTIONS[config_only]}" = no ]; then
        require_command pacman "This script targets Arch-family systems (pacman)."
        install_repo_packages "$source_dir" "$dry"
        if [ "${OPTIONS[aur]}" = yes ]; then
            install_aur_packages "$source_dir" "$dry"
        fi
    fi

    back_up_owned_dirs "$dest" "$stamp" "$dry"
    apply_configuration "$source_dir" "$dest" "$dry"
    create_screenshot_dir "$dry"
    report_secret_store
    validate_sway_config "$dest" "$dry"
    print_next_steps
}

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

# The one piece of mutable state, and parse_options is the only thing that
# writes it. Every step below takes what it needs as a parameter.
declare -A OPTIONS=([dry_run]=no [aur]=yes [config_only]=no [help]=no)

parse_options() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run)     OPTIONS[dry_run]=yes ;;
            --no-aur)      OPTIONS[aur]=no ;;
            --config-only) OPTIONS[config_only]=yes ;;
            -h|--help)     OPTIONS[help]=yes ;;
            *)             abort_with_usage "unknown option: $arg" ;;
        esac
    done
}

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

# ---------------------------------------------------------------------------
# Where things are
# ---------------------------------------------------------------------------

chezmoi_source_dir() {
    printf '%s/chezmoi\n' "$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
}

config_home() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

data_home() {
    printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}"
}

timestamp() {
    date +%Y%m%d-%H%M%S
}

owned_dir_paths() {
    local dest="$1" dir
    for dir in "${CONFIG_OWNED_DIRS[@]}"; do
        printf '%s/%s\n' "$dest" "$dir"
    done
}

apply_targets() {
    local dest="$1"
    owned_dir_paths "$dest"
    printf '%s/%s\n' "$dest" "$CONFIG_PORTAL_FILE"
}

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------

package_list() {
    local source_dir="$1" groups="$2"
    chezmoi execute-template --source "$source_dir" \
        "{{ range concat $groups }}{{ . }}
{{ end }}"
}

# The given packages that pacman does not have, one per line. Asked one at a
# time because `pacman -Qq a b c` answers with a single exit status and says
# nothing about which of the three it meant.
missing_packages() {
    local package
    for package in "$@"; do
        pacman -Qq "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
    done
}

install_repo_packages() {
    local source_dir="$1" dry="$2"
    local -a packages missing
    mapfile -t packages < <(package_list "$source_dir" "$CONFIG_REPO_PACKAGE_GROUPS")
    mapfile -t missing < <(missing_packages "${packages[@]}")

    if [ ${#missing[@]} -eq 0 ]; then
        say "Every repository package is already installed"
        return 0
    fi

    # Only the absent names, never the whole list. --needed skips a package only
    # when the installed version matches the sync database, and CachyOS ships
    # higher pkgrels than Arch, so the full list reads as a downgrade request:
    # pipewire 1:1.6.8-1.2 back to 1:1.6.8-1, which breaks the dependency
    # pipewire-alsa, pipewire-audio and pipewire-pulse declare, and then nothing
    # installs at all. See docs/kb/pacman-needed-wants-to-downgrade-cachyos-packages.md.
    say "Installing ${#missing[@]} missing package(s) from the repositories"
    run "$dry" sudo pacman -S --needed "${missing[@]}"
}

install_aur_packages() {
    local source_dir="$1" dry="$2"
    local -a packages missing
    mapfile -t packages < <(package_list "$source_dir" "$CONFIG_AUR_PACKAGE_GROUPS")

    mapfile -t missing < <(missing_packages "${packages[@]}")

    if [ ${#missing[@]} -eq 0 ]; then
        say "Every AUR package is already installed"
        return 0
    fi

    if ! command -v paru >/dev/null 2>&1; then
        echo "paru not found, skipping AUR packages: ${missing[*]}" >&2
        return 0
    fi

    say "Installing ${#missing[@]} missing AUR package(s)"
    run "$dry" paru -S --needed "${missing[@]}"
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

back_up_owned_dirs() {
    local dest="$1" stamp="$2" dry="$3"
    local dir

    say "Backing up any configuration already there"
    while IFS= read -r dir; do
        [ -e "$dir" ] || continue
        run "$dry" mv "$dir" "$dir.$stamp.bak"
    done < <(owned_dir_paths "$dest")
}

# --force because back_up_owned_dirs has already moved every target aside, so
# there is nothing left for chezmoi's overwrite guard to protect. Without it
# chezmoi asks "<target> has changed since chezmoi last wrote it?" and, with no
# TTY, dies on `could not open a new TTY`. That leaves the directories renamed to
# .bak and nothing written in their place, which looks like the script wiped
# ~/.config.
apply_configuration() {
    local source_dir="$1" dest="$2" dry="$3"
    local -a targets
    mapfile -t targets < <(apply_targets "$dest")

    say "Applying the sway configuration with chezmoi"
    run "$dry" mkdir -p "$dest"

    if [ "$dry" = yes ]; then
        chezmoi apply --source "$source_dir" --destination "$HOME" --dry-run -v "${targets[@]}"
    else
        chezmoi apply --source "$source_dir" --destination "$HOME" --force -v "${targets[@]}"
    fi
}

create_screenshot_dir() {
    local dry="$1"
    say "Creating the screenshot directory"
    run "$dry" mkdir -p "$HOME/$CONFIG_SCREENSHOT_DIR"
}

validate_sway_config() {
    local dest="$1" dry="$2"

    if [ "$dry" = yes ] || ! command -v sway >/dev/null 2>&1; then
        return 0
    fi

    say "Validating the generated sway config"
    if sway --validate --config "$dest/sway/config"; then
        echo "config parses"
    else
        echo "sway rejected the config, see the errors above" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Secret store
#
# Report rather than touch. A vault holds browser safe-storage keys, tokens and
# saved passwords, so guessing wrong here loses real data. All this does is say
# what is on disk and whether the login unlock can work, and leave the decisions
# to a human.
# ---------------------------------------------------------------------------

report_secret_store() {
    local data wallets keyrings
    data="$(data_home)"
    wallets="$(count_files "$data/kwalletd" '*.kwl')"
    keyrings="$(count_files "$data/keyrings" '*.keyring')"

    say "Checking for an existing secret store"
    [ "$wallets" -gt 0 ] && note "found a KDE wallet: $data/kwalletd"
    [ "$keyrings" -gt 0 ] && note "found a gnome-keyring store: $data/keyrings"

    case "$(secret_store_verdict "$wallets" "$keyrings")" in
        both)   report_conflicting_stores ;;
        none)   report_no_store ;;
        wallet) report_wallet_unlock "$(kwallet_unlock_status)" ;;
    esac
}

report_conflicting_stores() {
    note "Both stores exist. Only one process can own org.freedesktop.secrets, so"
    note "whichever starts first wins and the other one's contents become invisible."
    note "Decide which to keep before logging into sway, and migrate rather than"
    note "running both."
}

report_no_store() {
    note "no existing store. kwallet will create one on first use, and"
    note "its ksecretd serves org.freedesktop.secrets for every libsecret client."
}

report_wallet_unlock() {
    case "$1" in
        no-module)
            note "kwallet-pam is not installed, so the wallet will ask for a password"
            note "on every login. Install it to hand the login password over instead."
            ;;
        not-wired)
            note "pam_kwallet5.so is installed but no PAM stack calls it. The login"
            note "manager will not hand the password over; expect a prompt per login."
            ;;
        wired)
            note "pam_kwallet5 is wired into a PAM stack, and the sway config runs"
            note "pam_kwallet_init to finish the handover. The wallet should open on login."
            ;;
    esac
    note "This only works when the wallet password equals the login password."
}

secret_store_verdict() {
    local wallets="$1" keyrings="$2"
    if   [ "$wallets" -gt 0 ] && [ "$keyrings" -gt 0 ]; then echo both
    elif [ "$wallets" -gt 0 ];                          then echo wallet
    elif [ "$keyrings" -gt 0 ];                         then echo keyring
    else                                                     echo none
    fi
}

kwallet_unlock_status() {
    if [ ! -e "$CONFIG_KWALLET_PAM_MODULE" ]; then
        echo no-module
    elif grep -rq pam_kwallet5 "${CONFIG_PAM_DIRS[@]}" 2>/dev/null; then
        echo wired
    else
        echo not-wired
    fi
}

# ---------------------------------------------------------------------------
# Edges
# ---------------------------------------------------------------------------

# nullglob rather than counting `ls` output. Under `set -euo pipefail` an
# assignment from `ls missing/* | wc -l` takes the pipeline's status, which is ls
# failing on a directory that is not there, and the script ends without printing
# anything. That is what it did on a machine with a kwallet and no gnome-keyring.
count_files() {
    local dir="$1" glob="$2"
    local -a matches
    shopt -s nullglob
    matches=("$dir"/$glob)
    shopt -u nullglob
    printf '%s\n' "${#matches[@]}"
}

say() {
    printf '\n== %s\n' "$*"
}

note() {
    printf '  %s\n' "$*"
}

run() {
    local dry="$1"; shift
    if [ "$dry" = yes ]; then
        printf '  would run: %s\n' "$*"
    else
        "$@"
    fi
}

require_command() {
    local name="$1" message="$2"
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "$message" >&2
        exit 1
    fi
}

abort_with_usage() {
    echo "$1" >&2
    usage >&2
    exit 2
}

print_next_steps() {
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
}

main "$@"
