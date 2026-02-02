# workbuddy

Dotfiles and development environment management for Linux, macOS, and NixOS.

## Quick Start with Chezmoi

```bash
# Clone repo
git clone <repo> ~/workbuddy

# Initialize chezmoi with this source
chezmoi init --source ~/workbuddy/chezmoi

# Preview changes
chezmoi diff

# Apply dotfiles and run scripts
chezmoi apply -v
```

## What Gets Installed

### Via chezmoi scripts (run automatically)
- **Packages**: git, vim, tmux, zsh, curl (OS-specific package managers)
- **mise**: Tool version manager for Node.js, ripgrep, fzf, starship
- **oh-my-zsh**: ZSH framework with plugins
- **Vundle**: Vim plugin manager + plugins
- **Hack Nerd Font**: Patched font for terminal

### Dotfiles managed
- `.bashrc` + `.bashrc.d/` (modular bash configuration)
- `.zshrc` (oh-my-zsh with DevOps plugins)
- `.vimrc` (Vundle plugins, gruvbox theme, fzf integration)
- `.tmux.conf` (Ctrl-Space prefix, vim navigation)
- `.gitconfig` (aliases, colors, URL shortcuts)
- `.mise.toml` (tool versions)
- `.config/starship.toml` (cross-shell prompt)
- `.config/kitty/` (terminal emulator)
- `.config/sway/` (Wayland compositor - Linux only)
- `.config/waybar/` (status bar - Linux only)
- `.config/mako/` (notification daemon - Linux only)
- `.config/nvim/` (neovim sources vimrc)
- `.Xresources` (urxvt theme - Linux only)

## ZSH Plugins

The zsh configuration includes these oh-my-zsh plugins:
- git, z, fzf, kubectl, helm, docker, podman, aws, terraform, ansible

## Tool Versions (via mise)

Defined in `~/.mise.toml`:
```toml
[tools]
node = "lts"
ripgrep = "14.1.0"
fzf = "latest"
starship = "latest"
```

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
- Sway Wayland compositor with waybar
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
│   ├── dot_mise.toml           # -> ~/.mise.toml
│   ├── private_dot_config/     # -> ~/.config/
│   │   ├── starship.toml
│   │   ├── private_kitty/
│   │   ├── private_sway/
│   │   ├── private_waybar/
│   │   ├── private_mako/
│   │   └── private_nvim/
│   ├── private_dot_Xresources  # -> ~/.Xresources
│   └── nixos/                  # NixOS flake (not applied by chezmoi)
│       ├── flake.nix
│       ├── hosts/legion/
│       ├── modules/
│       └── home/
├── roles/                      # Legacy Ansible roles
├── local.yml                   # Legacy Ansible playbook
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
- `mod+h/j/k/l` - Navigate windows
- `mod+|` / `mod+-` - Split horizontal/vertical
- `mod+z` - Fullscreen
- `Print` - Screenshot to clipboard
- `mod+Print` - Screenshot region to clipboard
