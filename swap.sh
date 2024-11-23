#!/bin/bash

fallocate -l 2G /swapfile

chmod 600 /swapfile

mkswap /swapfile

swapon /swapfile

FSTAB_FILE="/etc/fstab"

FSTAB_LINE="/swapfile none swap sw 0 0"

if ! grep -Fxq "$FSTAB_LINE" $FSTAB_FILE; then
    echo "$FSTAB_LINE" | sudo tee -a $FSTAB_FILE
    echo "Add sting in $FSTAB_FILE"
else
    echo "The string already exists in $FSTAB_FILE"
fi

SYSCTL_FILE="/etc/sysctl.conf"

SYSCTL_LINE="vm.swappiness=10"

if ! grep -Fxq "$SYSCTL_LINE" $SYSCTL_FILE; then
    echo "$SYSCTL_LINE" | sudo tee -a $SYSCTL_FILE
    echo "Add sting in $SYSCTL_FILE"
else
    echo "The string already exists in $SYSCTL_FILE"
fi

sudo sysctl -p

echo "Successful install."
