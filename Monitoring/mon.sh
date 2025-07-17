#!/bin/bash

# Путь к лог-файлу
LOG_FILE="/home/www/monitor.log"

# Получение данных о CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

# Получение данных о памяти
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')

# Получение данных о дисковом пространстве
DISK_USAGE=$(df -h | awk '$NF=="/"{printf "%s", $5}')

# Текущая дата и время(+6)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Запись данных в лог-файл
echo "$TIMESTAMP CPU: $CPU_USAGE, Memory: $MEMORY_USAGE, Disk: $DISK_USAGE" >> $LOG_FILE
