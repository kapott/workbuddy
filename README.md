# workbuddy

Dotfiles and development environment management for Linux, macOS, and NixOS.

## Quick Start with Chezmoi

```bash
# Clone repo
git clone <repo> ~/workbuddy

# Initialize chezmoi with this source. It asks three questions once: git name,
# git email, and which of bash, zsh and fish becomes the login shell.
chezmoi init --source ~/workbuddy/chezmoi

# Preview changes
chezmoi diff

# Apply dotfiles and run scripts
chezmoi apply -v
```

## What Gets Installed

### Via chezmoi scripts (run automatically)
- **Packages**: git, vim, tmux, bash, zsh, fish, curl (OS-specific package managers)
- **mise**: Tool version manager (ansible-core, helm, kubectl, uv)
- **oh-my-zsh**: ZSH framework with plugins
- **Vundle**: Vim plugin manager + plugins
- **Hack Nerd Font**: Patched font for terminal
- **Login shell**: `chsh` to the shell picked at init, if it is not already that

### Picking a login shell

All three shells are configured and all three are installed, so the choice at
`chezmoi init` only decides what `getent passwd` returns. To switch afterwards,
edit `shell` in `~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply` again:
the choice is rendered into the script, so changing it changes the script's hash
and chezmoi runs it once more.

`chsh` asks for the account password. Over ssh, in a container or from an agent
there is nowhere to ask, so the script prints the command and moves on rather
than failing the apply. It also stops short when the shell is missing or absent
from `/etc/shells`, which is the one thing `chsh` refuses without saying why.

### Dotfiles managed
- `.bashrc` + `.bashrc.d/` (modular bash configuration)
- `.zshrc` (oh-my-zsh with DevOps plugins)
- `.vimrc` (Vundle plugins, gruvbox theme, fzf integration)
- `.tmux.conf` (Ctrl-Space prefix, vim navigation)
- `.gitconfig` (aliases, colors, URL shortcuts)
- `.config/fish/` (login shell: conf.d fragments and autoloaded functions)
- `.config/mise/config.toml` (tool versions)
- `.config/kitty/` (terminal emulator)
- `.config/sway/` (Wayland compositor plus its helper scripts - Linux only)
- `.config/quickshell/` (status bar, QML - Linux only)
- `.config/wofi/` (application launcher - Linux only)
- `.config/mako/` (notification daemon - Linux only)
- `.config/swaylock/` (screen locker - Linux only)
- `.config/kanshi/` (display hotplug profiles - Linux only)
- `.config/xdg-desktop-portal/` (portal backends for screen sharing under sway)
- `.config/nvim/` (neovim sources vimrc)
- `.Xresources` (urxvt theme - Linux only)

## ZSH Plugins

The zsh configuration includes these oh-my-zsh plugins:
- git, z, fzf, kubectl, helm, docker, podman, aws, terraform, ansible

## Tool Versions (via mise)

Defined in `~/.config/mise/config.toml`, which is the path `mise config` reports as active. It used
to be `~/.mise.toml`; both are global config paths and mise merges whatever it finds, so having two
meant two places to look when a version came out wrong.

```toml
[tools]
ansible-core = "2.20.5"
helm = "3.21.4"
kubectl = "latest"
uv = "0.11.7"
```

Tools the system package manager already ships (ripgrep, fzf, eza, bat, fd) are deliberately not
listed. Pinning them here as well puts a second binary in the shims directory ahead of the system
one, and the resulting version skew exists only inside your shell.

Fish activates mise in two modes, in `conf.d/40-mise.fish`: full activation for an interactive
shell, so a project's `mise.toml` and its `[env]` section apply when you cd into it, and shims only
for a non-interactive one, which is what an editor, a CI step or a devcontainer exec runs under.
Running both would put the shims ahead of the activated tools and resolve versions twice.

## Adding sway to a machine that already has a desktop

`install-sway.sh` installs the sway stack and writes only the sway-related
configs. It leaves the rest of the dotfiles alone, which is the point: a plain
`chezmoi apply` would also replace `.bashrc`, `.zshrc`, `.gitconfig` and the
kitty config on a machine you are still working on.

```bash
./install-sway.sh --dry-run      # show what it would install and write
./install-sway.sh                # packages + configs
./install-sway.sh --config-only  # skip pacman, just rewrite the configs
./install-sway.sh --no-aur       # skip wvkbd and autotiling
```

It backs up any existing `~/.config/sway`, `quickshell`, `wofi`, `mako` and
`swaylock` to `<dir>.<timestamp>.bak`, renders the templates through
`chezmoi execute-template` so the host-specific blocks resolve, and finishes with
`sway --validate`. Sway then appears as an extra session in the login manager;
the existing desktop stays installed and selectable.

Arch-family only. On other distros the chezmoi script covers the same ground.

### What gets installed

| Role | Package |
|------|---------|
| Compositor, lock, idle, wallpaper | sway, swaylock, swayidle, swaybg |
| Bar, launcher, notifications | quickshell, wofi, mako |
| Terminal | kitty |
| Screenshots | grim, slurp |
| Clipboard | wl-clipboard, cliphist |
| Brightness, media keys | brightnessctl, playerctl |
| Opened by a click in the bar | pavucontrol, btop |
| Daemons the bar reads over DBus | upower, networkmanager, bluez, pipewire, wireplumber |
| Display hotplug profiles | kanshi |
| Tray applets | network-manager-applet, blueman |
| Screen sharing | xdg-desktop-portal-wlr, xdg-desktop-portal-gtk |
| Qt apps on Wayland | qt6-wayland |
| Font | ttf-hack-nerd |
| On-screen keyboard (AUR) | wvkbd |
| Automatic split direction (AUR) | autotiling |

### Host-specific configuration

`chezmoi/private_dot_config/private_sway/config.tmpl` branches on
`.chezmoi.hostname`. Everything outside those branches is shared; outputs,
inputs and hardware keys live inside them. To add a machine, boot sway once with
the generic branch and read the real names off it:

```bash
swaymsg -t get_outputs
swaymsg -t get_inputs
```

The block for `endling` (ASUS ROG Flow Z13 GZ302EAC) covers what a convertible
needs and a laptop does not:

- `eDP-1` at scale 1.25, matching the 226 DPI panel. Fractional scaling makes
  XWayland clients blurry; drop to scale 1 if that trade goes the other way for you.
- `map_to_output eDP-1` on `type:touch` and `type:tablet_tool`. Without it, taps
  and stylus input land on the ultrawide.
- `bindswitch tablet:on|off`, driven by SW_TABLET_MODE on the Asus WMI hotkeys
  device. Detaching the keyboard cover widens the borders and brings up wvkbd.
- `autorotate.sh`, which follows the accelerometer through iio-sensor-proxy.
  Sway has no rotation of its own, and the touch devices have to be remapped on
  every turn or the axes end up mirrored.
- `lid.sh`, which blanks the panel on lid close only while another output is
  active. Unguarded, closing the cover away from the desk leaves you with no
  screen at all.
- The `asus::kbd_backlight` LED and the fan-profile key, through
  `brightnessctl -d` and `asusctl`.
- `session-env.sh`, which publishes the session variables to systemd and D-Bus
  only when no other compositor holds the display. Starting sway nested inside
  another session must not overwrite that session's `WAYLAND_DISPLAY`, because
  the systemd user manager is shared per user and quitting sway does not put the
  old values back. For the same reason the config does not include
  `/etc/sway/config.d/*`, where Arch ships an unguarded version of that import.

## NixOS Setup (Lenovo Legion 16ACH6H)

For NixOS on the Legion laptop:

```bash
# Symlink the NixOS configuration
sudo ln -sf ~/workbuddy/chezmoi/nixos /etc/nixos

# Generate hardware-configuration.nix for your system
sudo nixos-generate-config --show-hardware-config > /tmp/hw.nix
# Then merge relevant parts into nixos/hosts/legion/hardware-configuration.nix

# Update the bus IDs in modules/nvidia.nix
lspci | grep -E 'VGA|3D'  # Find your AMD and NVIDIA bus IDs

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#legion
```

### NixOS Features
- AMD Ryzen 5800H support with microcode updates
- NVIDIA hybrid graphics (PRIME offload mode)
- Sway Wayland compositor with a quickshell bar
- Power management via TLP and thermald
- Home Manager for user configuration

## Legacy Ansible Usage

The original Ansible playbooks are kept in `roles/` for reference.

```bash
# Install all tools locally
ansible-playbook local-tools.yml -i ./inventories/localhost --ask-become-pass

# Install only certain tools
ansible-playbook local-tools.yml -i ./inventories/localhost --tags vim,tmux --ask-become-pass

# Install desktop (legacy i3wm)
ansible-playbook local-i3wm.yml -i ./inventories/localhost --ask-become-pass
```

### Ansible Prerequisites
```bash
ansible-galaxy collection install community.general
```

## Verification

After installation:

```bash
# Verify chezmoi setup
chezmoi doctor

# Verify mise working
mise doctor

# Verify vim plugins
vim +PluginInstall +qall

# Verify fonts installed
fc-list | grep -i hack

# For NixOS
nixos-rebuild switch --flake .#legion
```

## Directory Structure

```
workbuddy/
├── chezmoi/                    # Chezmoi source directory
│   ├── .chezmoi.toml.tmpl      # Config with data prompts
│   ├── .chezmoiignore          # Files to ignore
│   ├── .chezmoiscripts/        # Installation scripts
│   ├── dot_bashrc              # -> ~/.bashrc
│   ├── dot_bashrc.d/           # -> ~/.bashrc.d/
│   ├── dot_zshrc.tmpl          # -> ~/.zshrc
│   ├── dot_vimrc               # -> ~/.vimrc
│   ├── dot_tmux.conf.tmpl      # -> ~/.tmux.conf
│   ├── dot_gitconfig.tmpl      # -> ~/.gitconfig
│   ├── private_dot_config/     # -> ~/.config/
│   │   ├── private_kitty/
│   │   ├── private_sway/       # config.tmpl + autorotate/lid/tablet-mode/toggle-osk
│   │   ├── private_quickshell/  # QML status bar
│   │   ├── private_wofi/
│   │   ├── private_mako/
│   │   ├── private_swaylock/
│   │   ├── private_kanshi/
│   │   ├── private_fish/       # conf.d/ fragments + functions/ (login shell)
│   │   ├── private_mise/       # -> ~/.config/mise/config.toml
│   │   ├── private_xdg-desktop-portal/
│   │   └── private_nvim/
│   ├── private_dot_Xresources  # -> ~/.Xresources
│   └── nixos/                  # NixOS flake (not applied by chezmoi)
│       ├── flake.nix
│       ├── hosts/legion/
│       ├── modules/
│       └── home/
├── roles/                      # Legacy Ansible roles
├── local.yml                   # Legacy Ansible playbook
├── install-sway.sh             # Add sway to a machine without touching other dotfiles
└── README.md
```

## Key Bindings Reference

### Tmux (prefix: Ctrl-Space)
- `|` - Horizontal split
- `-` - Vertical split
- `Ctrl-h/j/k/l` - Navigate panes (vim-style)
- `Ctrl-s` - Synchronize panes

### Vim (leader: Space)
- `Ctrl-p` - FZF file finder
- `Ctrl-f` - Ripgrep search
- `Space-gc` - Git commit
- `Space-gst` - Git status
- `Space-gp` - Git push

### Sway (mod: Super/Windows key)
- `mod+Return` - Terminal (kitty)
- `mod+Space` - Wofi launcher
- `mod+Shift+q` - Close window
- `mod+h/j/k/l` - Navigate windows
- `mod+Shift+h/j/k/l` - Move window
- `mod+|` / `mod+-` - Split horizontal/vertical
- `mod+z` - Fullscreen
- `mod+r` - Resize mode
- `mod+Ctrl+Left/Right` - Focus the other output
- `mod+Ctrl+</>` - Move workspace to the other output
- `mod+Ctrl+l` - Lock
- `mod+v` - Clipboard history
- `mod+o` - Toggle on-screen keyboard
- `Print` - Screenshot to clipboard
- `mod+Print` - Screenshot region to clipboard
- `mod+Shift+Print` - Screenshot region to `~/Pictures/Screenshots`

### Sway gestures (touchpad)
- Four fingers left/right - Next/previous workspace
- Three fingers up - Fullscreen
- Three fingers down - Toggle floating
