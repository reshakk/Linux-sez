#!/usr/bin/env bash

set -euo pipefail

#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
fi

swapoff -a

sed -i 's,\(/.*[[:space:]]none[[:space:]]*swap[[:space:]]\),#\1,' /etc/fstab

echo "Swap disabled"
