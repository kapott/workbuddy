# Keeps the CachyOS behaviour of a fastfetch banner on a new shell.
# To silence it, empty this function: `function fish_greeting; end`.
function fish_greeting
    type -q fastfetch; and fastfetch
end
