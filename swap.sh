#!/bin/bash

#swapon --show Выводит информацию о swap, если существует 

fallocate -l 2G /swapfile

chmod 600 /swapfile

mkswap /swapfile

swapon /swapfile

# Переменная для хранения пути к файлу /etc/fstab
FSTAB_FILE="/etc/fstab"

# Переменная для строки, которую нужно добавить в /etc/fstab
FSTAB_LINE="/swapfile none swap sw 0 0"

# Проверяем, есть ли уже такая строка в /etc/fstab
if ! grep -Fxq "$FSTAB_LINE" $FSTAB_FILE; then
    # Если строки нет, то добавляем её в конец файла
    echo "$FSTAB_LINE" | sudo tee -a $FSTAB_FILE
    echo "Строка добавлена в $FSTAB_FILE"
else
    echo "Строка уже существует в $FSTAB_FILE"
fi

# Переменная для хранения пути к файлу /etc/sysctl.conf
SYSCTL_FILE="/etc/sysctl.conf"

# Переменная для строки, которую нужно добавить в /etc/sysctl.conf
SYSCTL_LINE="vm.swappiness=10"

# Проверяем, есть ли уже такая строка в /etc/sysctl.conf
if ! grep -Fxq "$SYSCTL_LINE" $SYSCTL_FILE; then
    # Если строки нет, то добавляем её в конец файла
    echo "$SYSCTL_LINE" | sudo tee -a $SYSCTL_FILE
    echo "Строка добавлена в $SYSCTL_FILE"
else
    echo "Строка уже существует в $SYSCTL_FILE"
fi

# Применяем изменения для sysctl
sudo sysctl -p

echo "Все изменения применены."
