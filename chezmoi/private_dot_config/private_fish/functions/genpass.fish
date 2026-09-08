# genpass          -> 6-word diceware, for something a human types
# genpass -a [len] -> len chars A-Za-z0-9, default 40, for machines
#
# Wraps mkpw from personal-tools. Never generate a secret with
# `openssl rand -base64`: it emits + / and =, and each of those breaks in a
# different layer. + decodes as a space in a form-urlencoded body, / and =
# collide with base64 padding and URL paths, and the resulting auth failure
# never points at the secret itself.
function genpass
    if not type -q mkpw
        echo "genpass: mkpw not found, see personal-tools" >&2
        return 1
    end
    mkpw $argv
end
