#!/bin/bash

set -e

#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

# Install knockd if it's not already installed
if ! command -v knockd &> /dev/null; then
	echo "Installing knockd..."
	apt install knockd -y
else
	echo "Knockd is already installed."
fi

# Get the default network interface
eth_intf=$(ip route | grep default | awk '{print $5}')

read -p "Enter port: " port
read -p "Enter ports for port-knocking(e.g: 7000,8000,9000): " port_knock

# Write to /etc/knockd.conf
cat << EOF > "/etc/knockd.conf"
[options]
UseSyslog 
Interface = $eth_intf

[SSH]
sequence = $port_knock
seq_timeout = 5
tcpflags = syn
start_command = /sbin/iptables -I INPUT -s %IP% -p tcp --dport $port -j ACCEPT 
stop_command = /sbin/iptables -D INPUT -s %IP% -p tcp --dport $port -j ACCEPT 
cmd_timeout = 60

EOF

# Write to /etc/default/knockd
cat << EOF > "/etc/default/knockd"
START_KNOCKD=1
KNOCKD_OPTS="-i $eth_intf"
EOF

systemctl start knockd
systemctl enable knockd 

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport "$port" -j REJECT
apt install iptables-persistent 
service netfilter-persistent save
