# cputop [count] shows the busiest processes by CPU. Default 10.
function cputop --argument num
    test -z "$num"; and set num 10
    ps aux | sort -nr -k 3 | tr -s ' ' | cut -d ' ' -f 1,2,3,11 | head -n $num
end
