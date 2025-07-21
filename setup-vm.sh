#!/usr/bin/env bash


set -e

#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
fi



install_packages() {
	if ! which bzip2 wget curl ip net-tools iftop traceroute cron lsof iptables openssl; then
		if which apt >/dev/null 2>&1; then
			apt update
			DEBIAN_FRONTEND=noninteractive apt install bzip2 wget curl ip net-tools iftop traceroute cron lsof iptables openssl -y
			return 0
		fi
	if which yum >/dev/null 2>&1; then
		yum makecache
		yum install epel-release -y || true
		yum install bzip2 wget curl ip net-tools iftop traceroute cron lsof iptables openssl -y
		return 0
	fi
	echo "OS is not supported!"
	return 1
	fi
}

install_packages

if [[ $? -eq 0 ]]; then
        echo "Package install successfully. Starting main-script..."
        sleep 2
else
        echo "Failed to install packages."
        exit
fi

username_request() {
	while true; do
		read -r -p $'\n'"new username: " username
		if id "$username" >/dev/null 2>&1; then
			echo -e "\nUser $username exists!\n"
		else
			break
		fi
	done
}

iptables_add() {
	if ! iptables -C "$@" &>/dev/null; then
		iptables -A "$@"
	fi
}


main_func() {

	echo -e "\n====================\nSetting timezone\n===================="
	while true; do
		read -r -n 1 -p "Continue or Skip? (c|s)" cs
		case $cs in
			[Cc]*)
				timedatectl set-timezone Europe/Moscow
				systemctl restart systemd-timesyncd.service
				timedatectl
				echo -e "\nDONE\n"
				break
				;;
			[Ss]*)
				echo -e "\n"
				break
				;;
			*) echo -e "\nPlease answer C or S!\n" ;;
		esac
	done


	if [ ! -f /etc/ssh/sshd_config ]; then
	  echo -e "\n====================\nFile /etc/ssh/sshd_config not found!\n====================\n"
	  exit 1
	fi

	if [ ! -f /etc/default/grub ]; then
	  echo -e "\n====================\nFile /etc/default/grub not found!\n====================\n"
	  exit 1
	fi

	echo -e "\n====================\nNew user\n===================="

	while true; do
	  read -r -n 1 -p "Continue or Skip? (c|s) " cs
	  case $cs in
		  [Cc]*)
		    username_request

		    read -r -p "new password: " -s password

		    useradd -p "$(openssl passwd -1 "$password")" "$username" -s /bin/bash -m 
		    cp -r /root/.ssh/ /home/"$username"/ && chown -R "$username":"$username" /home/"$username"/.ssh/
		    echo -e "\n\nDONE\n"
		    break
		    ;;
    		[Ss]*)
		    new_port=22
		    echo -e "\n"
		    break
		    ;;
	    	*) echo -e "\nPlease answer C or S!\n" ;;
	  esac
	done


	echo -e "\n====================\nEdit sshd_config file\n===================="

	while true; do
	  read -r -n 1 -p "Continue or Skip? (c|s) " cs
	  case $cs in
	  [Cc]*) 
	    read -r -p "New ssh-port: " -s new_port
	    sed -i 's/#\?\(Port\s*\).*$/\1 $new_port/' /etc/ssh/sshd_config
	    sed -i 's/#\?\(PermitRootLogin\s*\).*$/\1 no/' /etc/ssh/sshd_config
	    sed -i 's/#\?\(PubkeyAuthentication\s*\).*$/\1 yes/' /etc/ssh/sshd_config
	    sed -i 's/#\?\(PermitEmptyPasswords\s*\).*$/\1 no/' /etc/ssh/sshd_config
	    sed -i 's/#\?\(PasswordAuthentication\s*\).*$/\1 no/' /etc/ssh/sshd_config
	    echo -e "\n\n"
	    /etc/init.d/ssh restart
	    echo -e "\nDONE\n"
	    break
	    ;;

	  [Ss]*)
	    new_port=22
	    echo -e "\n"
	    break
	    ;;
	  *) echo -e "\nPlease answer C or S!\n" ;;
	  esac
	done

	echo -e "\n====================\nDisabling ipv6\n===================="

	while true; do
	  read -r -n 1 -p "Continue or Skip? (c|s) " cs
	  case $cs in
	  [Cc]*)
	    echo -e "\n\n"
	    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&ipv6.disable=1 /' /etc/default/grub
	    sed -i 's/^GRUB_CMDLINE_LINUX="/&ipv6.disable=1 /' /etc/default/grub
	    update-grub
	    echo -e "\nDONE\n"
	    break
	    ;;

	  [Ss]*)
	    echo -e "\n"
	    break
	    ;;
	  *) echo -e "\nPlease answer C or S!\n" ;;
	  esac
	done


	echo -e "\n====================\nPromt for users\n===================="
	cat <<EOF >> /etc/bash.bashrc
	if [ "$color_prompt" = yes ]; then
    		if [ $(id -u) -eq 0 ]; then # you are root, make the prompt red
		#!standard PS		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
			#! ROOT = RED
      			PS1='\[\e[0;1;2m\][\[\e[0;1;2;4m\]\A\[\e[0;1;2m\]]\[\e[0;1;38;5;105m\][\[\e[0;1;38;5;202m\]\!\[\e[0;1;38;5;105m\]]\[\e[0;1;2;38;5;160m\]\u\[\e[0;1;38;5;214m\]@\[\e[0;1;38;5;68m\]\h\[\e[0;1m\]:\[\e[0;2m\]\w\[\e[0;1m\][\[\e[0;1m\]$?\[\e[0;1m\]]\[\e[0;1;2m\]\$ \[\e[0m\]'
        	else
			#! USER = GREEN
      			PS1='\[\e[0;1;2m\][\[\e[0;1;2;4m\]\A\[\e[0;1;2m\]]\[\e[0;1;38;5;105m\][\[\e[0;1;38;5;202m\]\!\[\e[0;1;38;5;105m\]]\[\e[0;1;2;38;5;112m\]\u\[\e[0;1;38;5;214m\]@\[\e[0;1;38;5;68m\]\h\[\e[0;1m\]:\[\e[0;2m\]\w\[\e[0;1m\][\[\e[0;1m\]$?\[\e[0;1m\]]\[\e[0;1;2m\]\$ \[\e[0m\]'
    		fi
	else
    		PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
	fi
EOF

	echo -e "\n====================\nIptables config\n===================="
	while true; do
	  read -r -n 1 -p "Current ssh session may drop! To continue you have to relogin to this host via $new_port ssh-port and run this script again. Continue or skip? (c|s) " cs
	  case $cs in
	  [Cs]*) #---DNS---
	    iptables_add OUTPUT -p tcp --dport 53 -j ACCEPT -m comment --comment dns
	    iptables_add OUTPUT -p udp --dport 53 -j ACCEPT -m comment --comment dns
	    #---NTP---
	    iptables_add OUTPUT -p udp --dport 123 -j ACCEPT -m comment --comment ntp
	    #---ICMP---
	    iptables_add OUTPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	    iptables_add INPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	    #---loopback---
	    iptables_add OUTPUT -o lo -j ACCEPT
	    iptables_add INPUT -i lo -j ACCEPT
	    #---Input-SSH---
	    iptables_add INPUT -p tcp --dport $new_port -j ACCEPT -m comment --comment ssh
	    #---Output-HTTP---
	    iptables_add OUTPUT -p tcp -m multiport --dports 443,80 -j ACCEPT
	    #---ESTABLISHED---
	    iptables_add INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	    iptables_add OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	    #---INVALID---
	    iptables_add OUTPUT -m state --state INVALID -j DROP
	    iptables_add INPUT -m state --state INVALID -j DROP
	    #---Defaul-Drop---
	    iptables -P OUTPUT DROP
	    iptables -P INPUT DROP
	    iptables -P FORWARD DROP
	    # save iptables config
	    echo -e "\n====================\nSaving iptables config\n====================\n"
	    service netfilter-persistent save
	    echo -e "DONE\n"
	    break
	    ;;
	  [Ss]*)
	    echo -e "\n"
	    exit
	    ;;
	  *) echo -e "\nPlease answer Y or N!\n" ;;
	  esac
	done
}

main_func

echo -e "\nOK\n"
exit 0
