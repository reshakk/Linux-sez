# If you have ps_mem in your system, you can check memory of apps
# Or python script - https://github.com/pixelb/ps_mem/blob/master/ps_mem.py

ps axo rss,comm,pid | awk '{ proc_list[$2] += $1; } END { for (proc in proc_list) { printf("%d\t%s\n", proc_list[proc],proc); }}' | sort -n | tail -n 10 | sort -rn | awk '{$1/=1024;printf "%.0fMB\t",$1}{print $2}'
