# tunnelfrom host:port forwards a remote port to the same port on localhost.
# Hostnames, ports and keys come from ~/.ssh/config.
function tunnelfrom --argument target
    if test -z "$target"
        echo "usage: tunnelfrom host:port" >&2
        return 2
    end
    set -l hostname (string split -f1 ':' $target)
    set -l portnum (string split -f2 ':' $target)
    if test -z "$portnum"
        echo "usage: tunnelfrom host:port" >&2
        return 2
    end
    ssh -fNL $portnum:127.0.0.1:$portnum $hostname
end
