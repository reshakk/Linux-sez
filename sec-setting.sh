#!/usr/bin/env bash

set -e

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

SSHD_CONFIG="/etc/ssh/sshd_config"

validate_port() {
	if ! [[ "$1" ~= ^[0-9]+$ ]] || [[ "$1" -le 1024 ]] || [[ "$1" -ge 65535 ]]; then
		echo "Invalid port number. Please enter a number between 1025 and 65535."
		exit 1
	fi
}

validate_name() {
	if ! [[ $1 ~= ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
		echo "Invalid username. Usernames must start with a letter or underscore and can only contain letters, numbers, and underscores."
		exit 1
	fi
}

read -p "Enter new port(It's better to choose after 1024): " PORT
validate_port "$PORT"

read -p "Enter name for new user: " NAME
validate_name "$NAME"

if id "$NAME" &>/dev/null; then
	echo "User '$NAME' already exists!"
	exit 1
fi

useradd -ms /bin/bash "$NAME" || echo "Failed to create user '$NAME'."
passwd "$NAME" || echo "Failed to set password for user '$NAME'."

echo "Create a backup for $SSHD_CONFIG"
echo ""

# Backup the original sshd_config
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak"

# Update SSHD configuration
if grep -q "^#Port 22" "$SSHD_CONFIG"; then
    sed -i "s/^#Port 22/Port $PORT/" "$SSHD_CONFIG"
elif grep -q "^Port " "$SSHD_CONFIG"; then
    sed -i "s/^Port .*/Port $PORT/" "$SSHD_CONFIG"
else
    echo "Port $PORT" >> "$SSHD_CONFIG"
fi

sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' "$SSHD_CONFIG" || echo "PermitRootLogin line not found."

echo "AllowUsers $NAME" >> "$SSHD_CONFIG"

service ssh restart

echo "User  '$NAME' created and SSH configuration updated successfully."
