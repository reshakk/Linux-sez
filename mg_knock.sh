#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

# Get the ssh-port
PORT=$( grep "Port" /etc/ssh/sshd_config | awk "{print $2}" | tail -n1 )
if [ -z $PORT ]; then
	PORT=22
fi

# Get the default network interface
ETH_INTF=$(ip route | grep default | awk '{print $5}')

KNOCK_FILE="/etc/knockd.conf"

install_knock() {
	# Install knockd if it's not already installed
	if ! command -v knockd &> /dev/null; then
		echo "Installing knockd..."
		apt install knockd -y
	else
		echo "Knockd is already installed."
	fi

	read -p "Enter ports for port-knocking(e.g: 7000,8000,9000): " PORT_KNOCK

	# Write to /etc/knockd.conf
	cat << EOF > "$KNOCK_FILE"
	[options]
	UseSyslog 
	Interface = $ETH_INTF

	[SSH]
	sequence = $PORT_KNOCK
	seq_timeout = 5
	tcpflags = syn
	start_command = /sbin/iptables -I INPUT -s %IP% -p tcp --dport $PORT -j ACCEPT 
	stop_command = /sbin/iptables -D INPUT -s %IP% -p tcp --dport $PORT -j ACCEPT 
	cmd_timeout = 60

	EOF

	cat << EOF > "$KNOCK_FILE"
	START_KNOCKD=1
	KNOCKD_OPTS="-i $ETH_INTF"
	EOF

	systemctl start knockd
	systemctl enable knockd 

	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -p tcp --dport "$PORT" -j REJECT
	apt install iptables-persistent 
	service netfilter-persistent save
}

disable_knock() {

	systemctl disable knockd

	iptables -D INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -D INPUT -p tcp --dport "$PORT" -j REJECT
	apt install iptables-persistent 
	service netfilter-persistent save

}


read -p "Install or Disable(i/d): " choice

if [[ "$choice" =~ ^[Ii]$ ]]; then
	echo "Install"
elif [[ "$choice" =~ ^[Dd]$ ]]; then
	echo "Disable"
else
	echo "Uncorrect options"
	exit 1
fi
