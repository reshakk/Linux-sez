#!/usr/bin/env bash

set -e

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

SSHD_CONFIG="/etc/ssh/sshd_config"

read -p "Enter new port(It's better to choose after 1024): " PORT
read -p "Enter name for new user: " NAME

if id "$NAME" &>/dev/null; then
	echo "User '$NAME' already exists!"
	exit 1
fi

useradd -m "$NAME"
passwd "$NAME"

if grep -q "^#Port 22" "$SSHD_CONFIG"; then
	sed -i "s/^#Port 22/Port $PORT/" "$SSHD_CONFIG"
fi

sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' "$SSHD_CONFIG" || echo "PermitRootLogin line not found."

echo "AllowUsers $NAME" >> "$SSHD_CONFIG"

service restart ssh

# Setup knockd on server
./start-knock.sh
