# memtop [count] shows the biggest processes by resident memory. Default 10.
function memtop --argument num
    test -z "$num"; and set num 10
    ps aux | sort -nr -k 4 | tr -s ' ' | cut -d ' ' -f 1,2,4,11 | head -n $num
end
