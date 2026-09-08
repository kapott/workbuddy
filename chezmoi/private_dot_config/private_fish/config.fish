# Fish is the login shell on these machines. Everything modular lives in
# conf.d/*.fish (sourced automatically, in name order) and functions/*.fish
# (autoloaded on first call), which mirrors how ~/.bashrc.d works for bash.
#
# Deliberately not sourcing /usr/share/cachyos-fish-config/cachyos-config.fish
# wholesale. The useful pieces are copied into conf.d instead, so this file
# behaves the same on a machine that is not CachyOS, and so an alias I did not
# ask for cannot appear after a distro package update. The one part worth
# keeping by reference is done.fish, sourced below.

# done: desktop notification when a long command finishes. Tuning lives in
# universal variables (__done_min_cmd_duration, __done_notification_urgency_level).
if test -f /usr/share/cachyos-fish-config/conf.d/done.fish
    source /usr/share/cachyos-fish-config/conf.d/done.fish
end

# Escape hatch for machine-local settings that should not be in git.
if test -f ~/.fish_profile
    source ~/.fish_profile
end
