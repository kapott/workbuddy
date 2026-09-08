# certspotter <domain> lists names seen in issued certificates, subdomains included.
function certspotter --argument domain
    if test -z "$domain"
        echo "usage: certspotter <domain>" >&2
        return 2
    end
    curl -s "https://api.certspotter.com/v1/issuances?domain=$domain&include_subdomains=true&expand=dns_names" \
        | jq -r '.[].dns_names[]' \
        | string replace -a '*.' '' \
        | sort -u \
        | grep $domain
end
