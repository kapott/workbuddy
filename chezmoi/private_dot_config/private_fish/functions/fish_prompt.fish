# Two-line prompt, the same shape as the bash one in ~/.bashrc.d/01-prompt:
#
#   14:32 therder@endling [~/Documents/git/personal/workbuddy] : main
#   [0] $
#
# Colours are the 256-colour indices that prompt uses, written as hex because
# set_color takes no index: 90 grey, 154 green, 122 cyan, 227 yellow. Change one
# side and change the other, or the two shells stop looking alike.

function fish_prompt --description 'Time, user@host, cwd, git branch, exit status'
    # Has to come first. Anything below sets $status itself.
    set -l last_status $status

    set_color 767676
    printf '%s' (date '+%H:%M')
    set_color normal
    printf ' '

    set_color afd700
    printf '%s' $USER
    set_color --bold normal
    printf '@'
    set_color afd700
    printf '%s' (prompt_hostname)
    set_color normal

    printf ' ['
    set_color 87ffd7
    printf '%s' (string replace -- $HOME '~' $PWD)
    set_color normal
    printf '] : '

    set_color ffff5f
    printf '%s' (_prompt_git_branch)
    set_color normal

    printf '\n['
    set_color 767676
    printf '%d' $last_status
    set_color normal
    printf '] '

    if fish_is_root_user
        printf '# '
    else
        printf '$ '
    end
end

# Silent outside a repository, which is what `git branch --show-current` already
# does; the redirect is for the "not a git repository" line on stderr.
function _prompt_git_branch
    command git branch --show-current 2>/dev/null
end
