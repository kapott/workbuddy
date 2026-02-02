# i3 to Sway Migration

This documents the software replacements made when migrating from X11/i3 to Wayland/Sway.

## Replaced Software

| X11/i3 | Wayland/Sway | Description |
|--------|--------------|-------------|
| i3 | sway | Tiling window manager / compositor |
| polybar | waybar | Status bar |
| rofi | wofi | Application launcher |
| dunst | mako | Notification daemon |
| feh | swaybg | Wallpaper setter |
| flameshot | grim + slurp | Screenshot tools |
| picom | *(not needed)* | Compositor (built into Wayland) |
| xss-lock | swayidle + swaylock | Screen locker / idle management |
| xclip / xsel | wl-clipboard | Clipboard utilities |
| arandr | wlr-randr | Display configuration |
| lightdm | greetd | Display manager |

## Key Differences

- Sway config is mostly compatible with i3, but uses `output` instead of `xrandr`
- Wayland apps use `app_id` instead of `class` for window matching
- No need for a separate compositor (picom) - Wayland handles compositing natively
- Screenshots use `grim` (capture) and `slurp` (region selection) piped to `wl-copy`
- Environment variables needed: `MOZ_ENABLE_WAYLAND=1`, `XDG_SESSION_TYPE=wayland`
