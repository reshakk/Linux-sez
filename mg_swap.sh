#!/usr/bin/env bash

#swapon --show

set -euo pipefail

SWAP_SIZE=2G
SWAP_FILE="/swapfile"
FSTAB_FILE="/etc/fstab"
FSTAB_LINE="$SWAP_FILE none swap sw 0 0"
SYSCTL_FILE="/etc/sysctl.conf"
SYSCTL_COUNT="10"
SYSCTL_LINE="vm.swappiness=$SYSCTL_COUNT"


if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 
fi

valid_size() {
	if ! [[ $SWAP_SIZE ~= ^[0-9]+[MG]$ ]];then
		echo "ERROR: Invalid size (size should look like that: 512M, 2G)"
		exit 1
	fi
}

function create_swap() {

	valid_size
	
	fallocate -l $SWAP_SIZE $SWAP_FILE

	chmod 600 $SWAP_FILE

	mkswap $SWAP_FILE

	swapon $SWAP_FILE


	if ! grep -Fxq "$FSTAB_LINE" $FSTAB_FILE; then
	    echo "$FSTAB_LINE" | sudo tee -a $FSTAB_FILE
	    echo "Add string in $FSTAB_FILE"
	else
	    echo "String is already exist in $FSTAB_FILE"
	fi


	if ! grep -Fxq "$SYSCTL_LINE" $SYSCTL_FILE; then
	    echo "$SYSCTL_LINE" | sudo tee -a $SYSCTL_FILE
	    echo "Add string in $SYSCTL_FILE"
	else
	    echo "String is already exist in $SYSCTL_FILE"
	fi

	sysctl -p

	echo "All changes have been accepted."
}

function enable_swap() {

	sed -i 's,^#\(/.*[[:space:]]none[[:space:]]*swap[[:space:]]\),\1,' "$FSTAB_FILE"

	# Enable swap
	swapon -a

	echo "Swap is enable"
}

function disable_swap(){

	swapoff -a

	sed -i '/#.*\/swap.img/s/^#//' "$FSTAB_FILE"

	echo "Swap disabled"
}

function show_help() {
	echo "Swap manager"
	echo ""
	echo "$0 --help"
	echo "$0 [ -c size ] [ -e ] [ -d ]"
	echo "$0 --create [size] (e.g., 512M, 2G, default: 2G) "
	echo "$0 --enable"
	echo "$0 --disable"
	exit 0
}


[ $# -eq 0 ] && show_help

while [ $# -gt 0 ]; do 
	case $1 in 
		-h | --help) 
			show_help
			;;
		-c | --create)
			shift
			[ $# -gt 0 ] && SWAP_SIZE=$1 || SWAP_SIZE=2G
			create_swap
			break
			;;
		-e | --enable)
			enable_swap
			break
			;;
		-d | --disable)
			disable_swap
			break
			;;
		*)
			echo "ERROR: Unknown option $1"
			show_help
			;;
	esac
done


