# backup <file> -> <file>.bak, without stopping to think about it.
function backup --argument filename
    if test -z "$filename"
        echo "usage: backup <file>" >&2
        return 2
    end
    cp -- $filename $filename.bak
end
