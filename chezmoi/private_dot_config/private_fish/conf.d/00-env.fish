# Environment, matching ~/.bashrc.d/00-env.

set -gx EDITOR vim
set -gx VISUAL vim
set -gx TERMINAL kitty
set -gx BROWSER firefox

set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state

# -g on purpose. Without it fish_add_path writes to the universal
# fish_user_paths, which already exists here, so every shell start would bake
# these into ~/.config/fish/fish_variables. That file is machine state, not
# config, and a path that git owns should not also live there. Global scope is
# rebuilt from this file on every shell instead.
fish_add_path -g ~/.local/bin ~/.cargo/bin

# Ask for the sudo password through a graphical prompt when there is a session
# to show it in. Carried over from the old config.fish.
if test -n "$WAYLAND_DISPLAY" -o -n "$DISPLAY"
    test -x /usr/bin/ksshaskpass; and set -gx SUDO_ASKPASS /usr/bin/ksshaskpass
end

# libvirt talks to the system daemon, not the per-user session one.
set -gx LIBVIRT_DEFAULT_URI "qemu:///system"

# Read man pages through bat when it is available.
if type -q bat
    set -gx MANROFFOPT "-c"
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
end
