# biggestfiles [dir] [count] lists the largest files below dir, default . and 20.
function biggestfiles --argument finddir findnum
    test -z "$finddir"; and set finddir "."
    test -z "$findnum"; and set findnum 20
    find $finddir -type f -printf "%s\t%p\n" | sort -rn | head -n $findnum
end
