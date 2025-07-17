#!/bin/bash
# This script is constantly monitoring sonnection. If connection break out, then it tries to reboot and restores the previous environment. And make log
# All you can just use mosh


read -p "Write user and ip-address for ssh(user@example.com): " SERVER

#SERVER="user@example.com"
SESSION="remote_work"
SSH_OPTS="-o ServerAliveInterval=30 -o ServerAliveCountMax=3"

while true; do
    echo "[$(date +'%H:%M:%S')] Подключение к сессии $SESSION на $SERVER..."
   # ssh -t $SSH_OPTS $SERVER "tmux attach -t $SESSION || tmux new -s $SESSION"
    
    if [ $? -eq 0 ]; then
        break
    else
        sleep 5
    fi
done
