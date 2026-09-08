# crtsh <domain> pulls hostnames out of crt.sh's HTML for a domain.
# SQL wildcards work: crtsh '%.byteherder.com'.
function crtsh --argument query
    if test -z "$query"
        echo "usage: crtsh <domain|%pattern%>" >&2
        return 2
    end
    set -l grep_domain (string replace -ra '%.*%' '' -- $query | string replace -a '%' '')
    curl -G -m 9000 -s --data-urlencode "q=$query" "https://crt.sh/" \
        | sed 's/<\/\?[^>]\+>//g' \
        | grep "$grep_domain" \
        | grep -v 'LIKE' \
        | grep -v 'crt.sh | %' \
        | sed 's/<[^>]*>/ /g' \
        | tr -s '[:space:]' '\n' \
        | sort -u \
        | grep -viE '^(&nbsp;|after|at|issuer|not|before|serial|number|ID|CA|common|name|dns|public|crt\.sh|group|logged|by)$'
end
