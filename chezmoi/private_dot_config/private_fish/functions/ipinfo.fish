# ipinfo [addr] queries ipinfo.io. No argument means your own address.
function ipinfo --argument addr
    curl -s "http://ipinfo.io/$addr"
end
