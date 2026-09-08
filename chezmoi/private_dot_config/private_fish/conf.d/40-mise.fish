# mise, the version manager the dev flows and devcontainers depend on.
#
# Two modes on purpose. An interactive shell gets the full activation, which
# re-evaluates on every prompt and therefore picks up a project's mise.toml plus
# anything in its [env] section when you cd into it. A non-interactive shell
# gets shims only: no prompt hook to hang off, and that is what an editor, a CI
# step or a devcontainer exec actually runs under.
#
# Running both would put the shims directory in PATH ahead of the activated
# tools and quietly resolve versions twice, so it is one or the other.

if type -q mise
    if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end
