# Timestamped history, the way `history` behaves in bash with HISTTIMEFORMAT.
function history
    builtin history --show-time='%F %T ' $argv
end
