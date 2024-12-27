#!/usr/bin/env bash

# Uncomment the swap entry in /etc/fstab
sed -i 's,^#\(/.*[[:space:]]none[[:space:]]*swap[[:space:]]\),\1,' /etc/fstab

# Enable swap
swapon -a

echo "Swap is enable"
