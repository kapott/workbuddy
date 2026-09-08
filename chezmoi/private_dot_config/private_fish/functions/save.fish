# save <file> -> <file>_<today>. For when you want a way back before editing.
function save --argument filename
    if test -z "$filename"
        echo "usage: save <file>" >&2
        return 2
    end
    mv -- $filename $filename"_"(date +%F)
end
