# Interactive-only settings, matching ~/.bashrc.d/30-settings where fish has an
# equivalent. Fish already does case-insensitive completion, autocd through
# `cd`, and unlimited history, so the shopt list from bash has no counterpart.

status is-interactive; or exit 0

# fzf: prefer ripgrep so ignored files stay out and hidden files stay in.
if type -q rg
    set -gx FZF_DEFAULT_COMMAND "rg --files --hidden"
else
    set -gx FZF_DEFAULT_COMMAND "find -L"
end

# Ctrl-s / Ctrl-q as flow control is a trap on a terminal that already scrolls.
type -q stty; and stty -ixon 2>/dev/null

# !! and !$ from bash, via the oh-my-fish bang-bang approach. The functions are
# autoloaded from functions/.
if test "$fish_key_bindings" = fish_vi_key_bindings
    bind -M insert ! __history_previous_command
    bind -M insert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end
