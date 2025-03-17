#!/bin/bash

# File path 
LOG_FILE="/home/www/monitor.log"

# Getting CPU data
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

# Getting memory data
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')

# Getting disk data
DISK_USAGE=$(df -h | awk '$NF=="/"{printf "%s", $5}')

# Current data and time
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "$TIMESTAMP CPU: $CPU_USAGE, Memory: $MEMORY_USAGE, Disk: $DISK_USAGE" >> $LOG_FILE
