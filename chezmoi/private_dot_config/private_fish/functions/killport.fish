# killport <port> kills whatever is listening on it. Defaults to 80.
function killport --argument portnum
    test -z "$portnum"; and set portnum 80
    set -l pids (lsof -ti :$portnum)
    if test -z "$pids"
        echo "nothing listening on port $portnum" >&2
        return 1
    end
    kill $pids
end
