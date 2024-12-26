#!/bin/bash

set -e

#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

# Install snap if it's not already installed
if ! command -v snap &> /dev/null; then
	echo "Installing snap..."
	apt install snapd -y
else
	echo "Snap is already installed."
fi

echo "Installing Nextcloud..."
snap install nextcloud

read -p "Enter user name: " NAME
read -s -p "Enter password: " PASSW
echo ""
read -p "Enter trusted domains: " DOM

read -p "Do you wants to change HTTP/HTTPS ports? (y/n)" ANS

echo "Setting up Nextcloud..."
nextcloud.manual-install "$NAME" "$PASSW"
nextcloud.occ config:system:set trusted_domains 1 --value="$DOM"

nextcloud.enable-https self-signed

if [[ $ANS =~ ^[Yy]$ ]]; then
	read -p "Enter new HTTP port (default is 80): " HTTP_PORT
	read -p "Enter new HTTPS port (default is 443): " HTTPS_PORT

	HTTP_PORT=${HTTP_PORT:-80}
	HTTPS_PORT=${HTTPS_PORT:-443}

	snap set nextcloud ports.http="$HTTP_PORT" ports.https="$HTTPS_PORT"
	echo "HTTP port set to $HTTP_PORT and HTTPS port set to $HTTPS_PORT."
else
	echo "Keeping default ports (HTTP: 80, HTTPS: 443)."
fi

echo "Nextcloud installation and cofiguration completed successfully."
