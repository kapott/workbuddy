# sway logs "Overwriting binding mod4+ctrl+l"

## Context

Host `endling`, sway from `chezmoi/private_dot_config/private_sway/config.tmpl`. The
config had grown a pair of "focus the other output" bindings next to the existing
`swaylock` binding.

## Problem

On start and on `swaymsg reload`, sway logged:

```
Overwriting binding mod4+ctrl+l
```

at line 197 of the rendered config. Sway does not fail on this. It keeps the last
binding it read and drops the earlier one, so `Mod+Ctrl+l` stopped locking the screen and
started moving focus to the output on the right instead. Nothing else looked wrong.

## Solution

The two lines were not obviously the same key:

```
bindsym $mod+Ctrl+l exec $lock          # line 130
bindsym $mod+Ctrl+$right focus output right   # line 197 in the rendered file
```

`set $right l` at the top of the config, for vim-style direction keys. So
`$mod+Ctrl+$right` expands to exactly `Mod+Ctrl+l`. Grepping the config for `ctrl+l`
finds only one of the two; the variable hides the other.

Fixed by moving the output-focus bindings onto the arrow keys, which were free with that
modifier combination, and leaving the lock binding alone:

```
bindsym $mod+Ctrl+Right focus output right
bindsym $mod+Ctrl+Left focus output left
```

Validate before reloading. This renders the chezmoi template and parses it without
touching the running session:

```bash
chezmoi execute-template --source chezmoi/ < chezmoi/private_dot_config/private_sway/config.tmpl > /tmp/sway-check
sway --validate -c /tmp/sway-check
```

Hypotheses that turned out wrong along the way:

- **A stray `include /etc/sway/config.d/*` pulling in a distro binding.** Wrong: this
  config deliberately does not include that directory, and the duplicate was inside the
  file itself.
- **Grepping the config for `ctrl+l` proves there is only one such binding.** Wrong, and
  this is the trap. Search for the expansion of every direction variable
  (`$left`, `$down`, `$up`, `$right`), not just the literal letters.
