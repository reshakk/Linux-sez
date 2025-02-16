#!/usr/bin/env bash

#set -e

#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
fi

BACKTITLE=SRMS
MENU="Select an option:"
HEIGHT=30
WIDTH=60
CHOICE_HEIGHT=20

function message_box {
  local title=$1
  local message=$2
  whiptail \
    --clear \
    --backtitle "$BACKTITLE" \
    --title "$title" \
    --msgbox "$message" \
    $HEIGHT $WIDTH \
    3>&1 1>&2 2>&3
}


function main_menu() {
	local selection
	while true; do
		selection=$(whiptail --clear --backtitle "$BACKTITLE" --title "Server Management" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
			--ok-button "Select" --cancel-button "Exit" \
			"1" "Users Management" \
			"2" "Add user" \
			"3" "Swap" \
			"4" "Knockd" \
			"5" "Ssh" \
			"6" "Docker" \
			3>&1 1>&2 2>&3)
		if [[ $? -ne 0 ]]; then
			break
		fi
		case $selection in
			1) list_users_menu;;
			2) add_user;;
			3) swap_menu;;
			4) knockd_menu;;
			5) ssh_menu;;
			6) docker_menu;;
		esac
	done	
}


function add_user() {
	local username
	local password
	local message
	while true; do
		username=$(whiptail --clear \
			--backtitle "$BACKTITLE" --title "Add New User" \
			--inputbox "Enter username:" $HEIGHT $WIDTH \
			3>&1 1>&2 2>&3)
		if [[ $? -ne 0 ]]; then
			break
		fi
		if [[ ! $username =~ ^[a-z][a-zA-Z0-9]*$ ]]; then
			message_box "Invalid Username" "Username can only contain A-Z, a-z and 0-9"
			continue
		fi
		if id "$username" >/dev/null 2>&1; then
			message_box "Invalid Username" "Username already exists"
			continue
		fi
		password=$(whiptail --passwordbox "Enter password: " \
			--backtitle "$BACKTITLE" --title "Add User" \
			$HEIGHT $WIDTH \
			3>&1 1>&2 2>&3)
		if [[ $? -ne 0 ]]; then
			break
		fi
		
		# Create the user
		sudo useradd -m "$username" -p "$(openssl passwd -1 "$password")"	
		sudo chsh -s /bin/bash "$username"

		whiptail --clear --backtitle "$BACKTITLE" --title "Add New User" \
			--yes-button "View User" --no-button "Return" \
			--yesno 'User  "'"${username}"'" has been created.' \
			$HEIGHT $WIDTH \
			3>&1 1>&2 2>&3
		if [[ $? -ne 0 ]]; then
			break
		fi
		
		view_user_menu "${username}"
	done
}

function view_user_menu() {
	local username
	local user_config
	local current_groups
	local current_guid
	local current_shell
	local current_uid
	local current_directory
	local new_password
	local new_name
	local new_uid
	local new_guid
	local new_groups
	local new_shell
	local new_directory
	while true; do
		if [[ $# -gt 0 ]]; then
			username=$1
		else
			username=$(list_users_menu "View User")
			if [[ $? -ne 0 ]]; then
				return 0
			fi
		fi
		user_config=$(whiptail --title "Change $username Details" \
		--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
            	"1" "Change Password" \
            	"2" "Change Name" \
            	"3" "Change UID" \
            	"4" "Change GID" \
            	"5" "Change Groups" \
            	"6" "Change Shell" \
	    	"7" "Change Home Directory" \
		"8" "Delete User" \
            	"9" "Exit" 3>&1 1>&2 2>&3)
		if [[ $? -ne 0 ]]; then
			break
		fi
		case $user_config in
		1)
                	new_password=$(whiptail --passwordbox "Enter new password for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
                	echo "$username:$new_password" | chpasswd
                	message_box "Successfully" "Password changed successfully!"
                	;;
		2)
                	new_name=$(whiptail --inputbox "Enter new name for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
			if id "$new_name" >/dev/null 2>&1; then
				message_box "Invalid Username" "Username already exists"
				continue
			else
                		usermod -l "$new_name" "$username"
				mkdir /home/$new_name
				chown $new_name:$username /home/$new_name
				usermod -d /home/$new_name "$new_name"
                		message_box "Successfully" "Name changed successfully to '$new_name' !"
			fi
                	;;
            	3)
			current_uid=$(awk -F: -v user="$username" '$1 == user {print $3}' /etc/passwd)
			message_box "Current UID:" " '$current_uid' "
                	new_uid=$(whiptail --inputbox "Enter new UID for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
                	usermod -u "$new_uid" "$username"
                	message_box "Successfully" "UID changed successfully to '$new_uid' !"
                	;;
            	4)
			current_guid=$(awk -F: -v user="$username" '$1 == user {print $4}' /etc/passwd)
			message_box "Current GUID:" " '$current_guid' "
                	new_gid=$(whiptail --inputbox "Enter new GID for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
                	usermod -g "$new_gid" "$username"
                	message_box "Successfully" "GID changed successfully to '$new_gid' !"
                	;;
            	5)
			current_groups=$(groups $username)
                	message_box "Current Groups:" " $current_groups "
			new_groups=$(whiptail --inputbox "Enter new groups for $username (comma-separated):" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
                	usermod -G "$new_groups" "$username"
                	message_box "Successfully" "New group added successfully!"
                	;;
            	6)
			current_shell=$(awk -F: -v user="$username" '$1 == user {print $7}' /etc/passwd)
			message_box "Current Shell:" " $current_shell "
                	new_shell=$(whiptail --inputbox "Enter new shell for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
                	usermod -s "$new_shell" "$username"
                	message_box "Successfully" "Shell changed successfully to '$new_shell' !"
                	;;
	    	7)
			current_directory=$(awk -F: -v user="$username" '$1 == user {print $6}' /etc/passwd)
			message_box "Current Home Directory:" " '$current_directory' "
                	new_directory=$(whiptail --inputbox "Enter new home directory for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
			if [[ $? -ne 0 ]]; then
    				break
  			fi
                	usermod -d "$new_directory" "$username"
			mv "$current_directory/*" "$new_directory"
			#rm -rf "$current_directory"
                	message_box "Successfully" "Home directory changed successfully to '$new_directory' !"
                	;;
		8)
			if whiptail --title "Delete" --yesno "Do you want to delete $username ?" $HEIGHT $WIDTH; then
				userdel -r "$username"
				message_box "Successfully" " '$username' successfuly delete!"
			else
				break
			fi
			;;

		9)break;;
		esac
	done
}

function list_users_menu() {
	local title=$1
	local options
	local selection
	
	options=$(awk -F: '$3 > 999 && $3 < 65534 {print $1, $1}' /etc/passwd)

  	if [[ -z "$options" ]]; then
    		message_box "Error" "No User Found."
    		return
  	fi

  	selection=$(whiptail --clear --noitem --backtitle "$BACKTITLE" --title "$title" \
    	--menu "Select the user" $HEIGHT $WIDTH $CHOICE_HEIGHT $options \
    	--ok-button "Select" --cancel-button "Return" \
    	3>&1 1>&2 2>&3)
	if [[ $? -ne 0 ]]; then
    		return
  	fi

  	#echo "${selection}"
  	view_user_menu "${selection}"
}

function swap_menu() {
	local options
	while true; do
		options=$(whiptail --title "Swap Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Add 2Gb-Swap" \
		    "2" "Enable Swap" \
		    "3" "Disable Swap" \
		    "4" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/swap.sh")
				if [[ $? -eq 0 ]]; then
					message_box "Successfully" "Swap was set up and enabled."
				else
					message_box "Failed" "Failed to set up swap. Try it manually from github. "
				fi	
				
				;;
			2) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/start_swap.sh")
				if [[ $? -eq 0 ]]; then
					message_box "Successfully" "Swap enable."
				else
					message_box "Failed" "Failed enable swap. Try it manually from github. "
				fi	
				;;
			3) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/stop_swap.sh")	
				if [[ $? -eq 0 ]]; then
					message_box "Successfully" "Swap was successfully stopped."
				else
					message_box "Failed" "Failed to stop swap. Try it manually from github. "
				fi	
				;;
			4) break;;
		esac
	done
}

function knockd_menu() {
	local options
	local new_port
	while true; do
		options=$(whiptail --title "Knockd Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Enable Knockd" \
		    "2" "Change port for knocking" \
		    "3" "Disable Knockd" \
		    "4" "Delete Knockd" \
		    "5" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/start_knock.sh")
				if [[ $? -eq 0 ]]; then
					message_box "Successfully" "Port-knocking was successfully installed."
				else
					message_box "Failed" "Failed to started port-knocking. Try installing manually from github. "
				fi	
				;;
			2)
				new_port=$(whiptail --inputbox "Enter new port for port-knocking (e.g: 7000,8000,9000)" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
				if [[ $? -ne 0 ]]; then
    					break
  				fi
				sed -i "s/sequence = .*/sequence = $new_port/" /etc/knockd.conf
				
				if systemctl restart knockd.service; then
					message_box "Successfully" "Port changed successfully to '$new_port' "
				else
					message_box "Failed" "Failed to restart knockd"
				fi
				;;
			3) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/stop_knock.sh")
				if [[ $? -eq 0 ]]; then
					message_box "Successfully" "Port-knocking was successfully stopped."
				else
					message_box "Failed" "Failed to stoped service knockd. Try to stop it manually. "
				fi	
				;;
			4)
				apt remove knockd -y
				rm -f /etc/knockd.conf 
				rm -f /etc/default/knockd 
				rm -f /etc/systemd/system/knockd.service
				;;
			5) break;;
		esac
	done
}

function ssh_menu() {
	local options
	local new_port
	local list_user
	local selection
	local SSHD_CONFIG="/etc/ssh/sshd_config"
	while true; do
		options=$(whiptail --title "Ssh Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Change SSH-Port" \
		    "2" "Disable Root-Login and Allow User" \
		    "3" "Change maximum auth attempts" \
		    "4" "Disable passwd auth" \
		    "5" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1)
				new_port=$(whiptail --inputbox "Enter new ssh-port" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
				#read -p "Enter new port(It's better to choose after 1024): " PORT 
				if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [[ "$new_port" -le 1024 ]] || [[ "$new_port" -ge 65535 ]]; then
					message_box "Invalid" "Invalid port number. Please enter a number between 1025 and 65535."
					continue
				fi

				if grep -q "^#Port 22" "$SSHD_CONFIG"; then
					sed -i "s/^#Port 22/Port $new_port/" "$SSHD_CONFIG"
				elif grep -q "^Port " "$SSHD_CONFIG"; then
					sed -i "s/^Port .*/Port $new_port/" "$SSHD_CONFIG"
				else
					echo "Port $new_port" >> "$SSHD_CONFIG"
				fi

				if systemctl restart ssh.service; then
					message_box "Successfully" "Successfuly change port to '$new_port' "
				else
					message_box "Failed" "Something get wrong."
				fi
				;;
			2)

				list_user=$(awk -F: '$3 > 999 && $3 < 65534 {print $1, $1}' /etc/passwd)

  				if [[ -z "$list_user" ]]; then
    					message_box "Error" "No User Found."
    					return
				fi
				selection=$(whiptail --clear --noitem --backtitle "$BACKTITLE" --title "$title" \
					--menu "Select the user" $HEIGHT $WIDTH $CHOICE_HEIGHT $list_user \
					--ok-button "Select" --cancel-button "Return" \
					3>&1 1>&2 2>&3)
				if [[ $? -ne 0 ]]; then
					return
				fi

				if grep -q "^PermitRootLogin " "$SSHD_CONFIG"; then
        				sed -i "s/^PermitRootLogin .*/PermitRootLogin no/" "$SSHD_CONFIG"
				elif grep -q "^#PermitRootLogin " "$SSHD_CONFIG"; then
					sed -i "s/^#PermitRootLogin .*/PermitRootLogin no/" "$SSHD_CONFIG"
				else
					echo "PermitRootLogin no" >> "$SSHD_CONFIG"
				fi
				
				if grep -q "^AllowUsers " "$SSHD_CONFIG"; then
					sed -i "s/^AllowUsers .*/AllowUsers $selection/" "$SSHD_CONFIG"
				else
					echo "AllowUsers $selection" >> "$SSHD_CONFIG"
				fi

				if systemctl restart ssh.service; then
					message_box "Successfully" "Allow '$selection' ssh-connection "
				else
					message_box "Failed" "Something gone wrong."
				fi
				;;	
			3)
				autht=$(whiptail --inputbox "Enter maximum auth attempts" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
				if grep -q "^MaxAuthTries " "$SSHD_CONFIG"; then
        				sed -i "s/^MaxAuthTries .*/MaxAuthTries $autht/" "$SSHD_CONFIG"
				elif grep -q "^#MaxAuthTries " "$SSHD_CONFIG"; then
					sed -i "s/^#MaxAuthTries .*/MaxAuthTries $autht/" "$SSHD_CONFIG"
				else
					echo "MaxAuthTries $autht" >> "$SSHD_CONFIG"
				fi
								
				if systemctl restart ssh.service; then
					message_box "Successfully" "Successfully change max auth attempts to '$autht'. "
				else
					message_box "Failed" "Something gone wrong."
				fi
				;;
			4)
				if grep -q "^PasswordAuthentication " "$SSHD_CONFIG"; then
        				sed -i "s/^PasswordAuthentication .*/PasswordAuthentication no/" "$SSHD_CONFIG"
				elif grep -q "^#PasswordAuthentication " "$SSHD_CONFIG"; then
					sed -i "s/^#PasswordAuthentication .*/PasswordAuthentication no/" "$SSHD_CONFIG"
				else
					echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
				fi

				if systemctl restart ssh.service; then
					message_box "Successfully" "Successfully disable passwd auth."
				else
					message_box "Failed" "Something gone wrong."
				fi
				;;
			5)
				break
				;;
		esac
	done

}


function generate_flatnotes(){ #Add prompts
	local username=$(whiptail --inputbox "Please enter user name: "  $HEIGHT $WIDTH  3>&1 1>&2 2>&3)	
	local fpasswd=$(whiptail --passwordbox "Please enter password: "  $HEIGHT $WIDTH  3>&1 1>&2 2>&3)
	local secret_key=$(whiptail --passwordbox "Please enter secret-key: "  $HEIGHT $WIDTH  3>&1 1>&2 2>&3)
	local new_port=$(whiptail --inputbox "Please enter port: "  $HEIGHT $WIDTH "8080"  3>&1 1>&2 2>&3)
	mkdir -p /opt/flatnotes
	cat >"/opt/flatnotes/docker-compose.yaml" <<EOF
	version: "3"

	services:
  		flatnotes:
    		  container_name: flatnotes
    		  image: dullage/flatnotes:latest
    		  environment:
      		    PUID: 1000
		    PGID: 1000
      		    FLATNOTES_AUTH_TYPE: "password"
      		    FLATNOTES_USERNAME: "$username"
      		    FLATNOTES_PASSWORD: "$fpasswd"
      		    FLATNOTES_SECRET_KEY: "$secret_key"
    		  volumes:
     		     - "./data:/data"
      			# Optional. Allows you to save the search index in a different location: 
      			# - "./index:/data/.flatnotes"
    		  ports:
     		    - "$new_port:8080"
    		  restart: unless-stopped
EOF
}

function generate_nextcloud() {
	local nw_dock="nextcloud_network"
	local up_http=$(whiptail --inputbox "Please enter http-port: "  $HEIGHT $WIDTH "80" 3>&1 1>&2 2>&3)
	local up_https=$(whiptail --inputbox "Please enter https-port: "  $HEIGHT $WIDTH "443" 3>&1 1>&2 2>&3)
	local ip_addr=$(hostname -I | awk '{print $1}')
	local mysql_proot=$(whiptail --passwordbox "Enter new password for root-mysql:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
	local mysql_pdb=$(whiptail --passwordbox "Enter new password for mysql:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
	local mysql_user=$(whiptail --inputbox "Please enter name for sql-user: "  $HEIGHT $WIDTH "user" 3>&1 1>&2 2>&3)
	# docker network create $nw_dock
	mkdir -p /opt/nextcloud
	cat >"/opt/nextcloud/docker-compose.yaml" <<EOF
# NextCLoud with MariaDB/MySQL
#
# Access via "http://localhost:$up_http" (or "http://$ip_addr:$up_http" if using docker-machine)
#
# During initial NextCLoud setup, select "Storage & database" --> "Configure the database" --> "MySQL/MariaDB"
# Database user: $mysql_user 
# Database password: $mysql_pdb
# Database name: ncdb
# Database host: replace "localhost" with "maria-db" the same name as the data base container name.
#
#
# The reason for the more refined data persistence in the volumes is because if you were to
# use just the the '/var/www/html' then everytime you would want/need to update/upgrade
# NextCloud you would have to go into the volume on the host machine and delete 'version.php'
#

version: '2'

services:

  nextcloud:
    container_name: nextcloud
    restart: unless-stopped
    image: nextcloud
    ports:
      - $up_http:80
    volumes:
      - /opt/containerd/cloud/nextcloud/apps:/var/www/html/apps
      - /opt/containerd/cloud/nextcloud/config:/var/www/html/config
      - /opt/containerd/cloud/nextcloud/data:/var/www/html/data
    depends_on:
      - db

  db:
    container_name: maria-db
    restart: unless-stopped
    image: mariadb
    environment:
      MYSQL_ROOT_PASSWORD: $mysql_root
      MYSQL_DATABASE: ncdb
      MYSQL_USER: $mysql_user
      MYSQL_PASSWORD: $mysql_pdb
    volumes:
      - /opt/containerd/cloud/mariadb:/var/lib/mysql
EOF
}

function docker_menu() {
	local options
	while true; do
		options=$(whiptail --title "Docker Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Install Docker" \
		    "2" "Install Flatnotes" \
		    "3" "Install Passky" \
		    "4" "Install Nextcloud" \
		    "5" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1)
				if which docker docker-compose >/dev/null 2>&1; then
					message_box "Error" "Docker is already installed."
				else
					bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/docker_in.sh")
					if which docker docker-compose >/dev/null 2>&1; then
						message_box "Successfully" "Docker is installed."
					else
						message_box "Error" "Something gone wrong. Try installing manually from my github."
					fi
				fi
				;;
			2)
				if ! which docker docker-compose >/dev/null 2>&1; then
					message_box "Error" "Install docker."
				else
					generate_flatnotes
					if [[ $? -eq 0 ]] || [[ -f /root/flatnotes/docker-compose.yaml ]];  then
						message_box "Successfully" "Generation docker-compose.yaml is successfully. "
					else
						message_box "Error" "Something gone wrong. Try installing manually."
					fi
				fi
				;;
			3)
				message_box "Sorry" "This container doesn't work yet."
				;;
			4)
				if  which docker docker-compose >/dev/null 2>&1; then
					generate_nextcloud
					if [[ $? -eq 0 ]] || [[ -f /root/nextcloud/docker-compose.yaml ]];  then
						message_box "Successfully" "Generation docker-compose.yaml is successfully. "
					else
						message_box "Error" "Something gone wrong. Try installing manually."
					fi
				else
					message_box "Error" "Install docker."
				fi

				;;
			5)break;;
		esac
	done

}

function install_packages() {
  if ! which wget whiptail curl zip unzip >/dev/null 2>&1; then
    if which apt >/dev/null 2>&1; then
      apt update
      DEBIAN_FRONTEND=noninteractive apt install wget whiptail curl zip unzip -y
      return 0
    fi
    if which yum >/dev/null 2>&1; then
      yum makecache
      yum install epel-release -y || true
      yum install wget whiptail curl zip unzip -y
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
	main_menu
else 
	echo "Failed to install packages."
	exit
fi






#main_menu
