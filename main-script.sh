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
			"7" "Nextcloud" \
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
			7) nextcloud_menu;;
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
                	echo "$username:$new_password" | chpasswd
                	message_box "Successfully" "Password changed successfully!"
                	;;
		2)
                	new_name=$(whiptail --inputbox "Enter new name for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
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
                	usermod -u "$new_uid" "$username"
                	message_box "Successfully" "UID changed successfully to '$new_uid' !"
                	;;
            	4)
			current_guid=$(awk -F: -v user="$username" '$1 == user {print $4}' /etc/passwd)
			message_box "Current GUID:" " '$current_guid' "
                	new_gid=$(whiptail --inputbox "Enter new GID for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
                	usermod -g "$new_gid" "$username"
                	message_box "Successfully" "GID changed successfully to '$new_gid' !"
                	;;
            	5)
			current_groups=$(groups $username)
                	message_box "Current Groups:" " $current_groups "
			new_groups=$(whiptail --inputbox "Enter new groups for $username (comma-separated):" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
                	usermod -G "$new_groups" "$username"
                	message_box "Successfully" "New group added successfully!"
                	;;
            	6)
			current_shell=$(awk -F: -v user="$username" '$1 == user {print $7}' /etc/passwd)
			message_box "Current Shell:" " $current_shell "
                	new_shell=$(whiptail --inputbox "Enter new shell for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
                	usermod -s "$new_shell" "$username"
                	message_box "Successfully" "Shell changed successfully to '$new_shell' !"
                	;;
	    	7)
			current_directory=$(awk -F: -v user="$username" '$1 == user {print $6}' /etc/passwd)
			message_box "Current Home Directory:" " '$current_directory' "
                	new_directory=$(whiptail --inputbox "Enter new home directory for $username:" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
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
	local optionslocal selection
	
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
				message_box "Successfully" "Swap successfully installed on your system."
				;;
			2) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/start-swap.sh")
				message_box "Successfully" "Swap successfully enable."
				;;
			3) 
				bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/stop-swap.sh")	
				message_box "Successfully" "Swap successfully stoped."
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
			1) bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/start-knock.sh");;
			2)
				new_port=$(whiptail --inputbox "Enter new port for port-knocking (e.g: 7000,8000,9000)" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
				sed -i "s/sequence = .*/sequence = $new_port/" /etc/knockd.conf
				if systemctl restart knockd.service; then
					message_box "Successfully" "Port changed successfully to '$new_port' "
				else
					message_box "Failed" "Failed to restart knockd"
				fi
				;;
			3) bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/stop-knock.sh");;
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
	local username
	local SSHD_CONFIG 
	SSHD_CONFIG="/etc/ssh/sshd_config"
	while true; do
		options=$(whiptail --title "Ssh Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Change SSH-Port" \
		    "2" "Root-Login and Allow User" \
		    "3" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1)
				new_port=$(whiptail --inputbox "Enter new ssh-port" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
				#read -p "Enter new port(It's better to choose after 1024): " PORT 
				if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [[ "$new_port" -le 1024 ]] || [[ "$new_port" -ge 65535 ]]; then
					echo "Invalid port number. Please enter a number between 1025 and 65535."
					continue
				fi

				if grep -q "^#Port 22" "$SSHD_CONFIG"; then
					sed -i "s/^#Port 22/Port $new_port/" "$SSHD_CONFIG"
				elif grep -q "^Port " "$SSHD_CONFIG"; then
					sed -i "s/^Port .*/Port $new_port/" "$SSHD_CONFIG"
				else
					echo "Port $new_port" >> "$SSHD_CONFIG"
				fi
				systemctl restart ssh.service

				message_box "Successfully" "Successfuly change port to '$new_port' "
				;;
			2)
				username=$(whiptail --inputbox "Enter username to allow ssh-connection" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
				if grep -q "^PermitRootLogin " "$SSHD_CONFIG"; then
        				sed -i "s/^PermitRootLogin .*/PermitRootLogin no/" "$SSHD_CONFIG"
				elif grep -q "^#PermitRootLogin " "$SSHD_CONFIG"; then
					sed -i "s/^#PermitRootLogin .*/PermitRootLogin no/" "$SSHD_CONFIG"
				else
					echo "PermitRootLogin no" >> "$SSHD_CONFIG"
				fi
				
				if grep -q "^AllowUsers " "$SSHD_CONFIG"; then
					sed -i "s/^AllowUsers .*/AllowUsers reshkk/" "$SSHD_CONFIG"
				else
					echo "AllowUsers reshkk" >> "$SSHD_CONFIG"
				fi
				systemctl restart ssh.service
				
				message_box "Successfully" "Allow '$username' ssh-connection "
				;;
			3)
				break
				;;
		esac
	done

}

function docker_menu() {
	local options
	while true; do
		options=$(whiptail --title "Docker Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Install Docker" \
		    "2" "Install Flatnotes" \
		    "3" "Install Passky" \
		    "4" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1)
				if which docker docker-compose >/dev/null 2>&1; then
					message_box "Error" "Docker is already installed."
				else
					bash <(curl -sL "https://raw.githubusercontent.com/reshakk/Ubuntu-gez/master/script/docker-in.sh")
					if which docker docker-compose >/dev/null 2>&1; then
						message_box "Successfully" "Docker is installed."
					else
						message_box "Error" "Something gone wrong. Try installing manually from my github."
					fi
				fi
				;;
			2)
				generate_flatnotes
				if [[ -f /root/flatnotes/docker.yml ]]; then
					message_box "Successfully" "Generation docker.yml is successfully. "
				else
					message_box "Error" "Something gone wrong. Try installing manually."
				fi
				;;
			3)
				mkdir -p /root/Passky
				cd /root/Passky
				bash <(curl -sL "https://raw.githubusercontent.com/Rabbit-Company/Passky-Server/refs/heads/main/installerGUI.sh")
				if [[ -f /root/Passky/docker.yml ]]; then
					message_box "Successfully" "Generation docker.yml is successfully. "
				else
					message_box "Error" "Something gone wrong. Try installing manually."
				fi
				;;
			4)
				break
				;;
		esac
	done

}

function generate_flatnotes(){
	mkdir -p /root/flatnotes
	touch /root/flatnotes/docker.yml
	cat >"/root/flatnotes/docker.yml" <<EOF
	version: "3"

	services:
  		flatnotes:
    		  container_name: flatnotes
    		  image: dullage/flatnotes:latest
    		  environment:
      		    PUID: 1000
		    PGID: 1000
      		    FLATNOTES_AUTH_TYPE: "password"
      		    FLATNOTES_USERNAME: "user"
      		    FLATNOTES_PASSWORD: "changeMe!"
      		    FLATNOTES_SECRET_KEY: "aLongRandomSeriesOfCharacters"
    		  volumes:
     		     - "./data:/data"
      			# Optional. Allows you to save the search index in a different location: 
      			# - "./index:/data/.flatnotes"
    		  ports:
     		    - "8080:8080"
    		  restart: unless-stopped
EOF
}

function nextcloud_menu() {
	local options
	local trusted_domains
	local current_domains
	local HTTP_PORT
	local HTTPS_PORT
	local username
	local new_password
	local confirm_password
	while true; do
		options=$(whiptail --title "Nextcloud Menu" \
			--menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		    "1" "Download and enable Nextcloud" \
		    "2" "Change Ports" \
		    "3" "Change Password" \
		    "4" "Change Trusted Domains" \
		    "5" "Exit" \
		    3>&1 1>&2 2>&3) 
		if [[ $? -ne 0 ]]; then
    			break
  		fi
		case $options in
			1)
				install_nextcloud
				message_box "Successfully" "Nextcloud successfully installed with snap. "
				;;
			2)
				HTTP_PORT=$(whiptail --inputbox "Enter new HTTP-Port:" $HEIGHT $WIDTH 3>&1 1>&2 2>3)
				HTTPS_PORT=$(whiptail --inputbox "Enter new HTTPS-Port:" $HEIGHT $WIDTH 3>&1 1>&2 2>3)
				snap set nextcloud ports.http="$HTTP_PORT" ports.https="$HTTPS_PORT"
				snap restart nextcloud
				;;
			3)
				
				username=$(whiptail --inputbox "Enter username:"$HEIGHT $WIDTH 3>&1 1>&2 2>3)
				new_password=$(whiptail --inputbox "Enter New Password:"$HEIGHT $WIDTH 3>&1 1>&2 2>3)
				confirm_password=$(whiptail --inputbox "Confirm the Password:"$HEIGHT $WIDTH 3>&1 1>&2 2>3)

				if [[ new_password != confirm_password ]]; then
					whiptail message_box "Invalid Password" "Password do not match"
					confirm
				fi
				sudo -u www-data php /var/www/nextcloud/occ user:resetpassword "$username" <<< "$NEW_PASSWORD"
				snap restart nextcloud

				message_box "Successfully" "The password has been changed for the $username "
				;;
			4)
				current_domains=$(nextcloud.occ config:system:get trusted_domains)
				message_box "Current Trusted Domains:" " '$current_domains' "
				trusted_domains=$(whiptail --inputbox "Enter trusted domains:"$HEIGHT $WIDTH 3>&1 1>&2 2>3)
				nextcloud.occ config:system:set trusted_domains 1 --value="$trusted_domains"
				snap restart nextcloud
				;;
			5)
				break
				;;
		esac
	done


}

function install_nextcloud() {
	local username
	local password
	local trusted_domains
	local HTTP_PORT
	local HTTPS_PORT

	snap install nextcloud #Add check out
	username=$(whiptail --inputbox "Enter username for admin:" $HEIGHT $WIDTH 3>&1 1>&2 2>3)
	password=$(whiptail --passwordbox "Enter password for admin:" $HEIGHT $WIDTH 3>&1 1>&2 2>3)
	trusted_domains=$(whiptail --inputbox "Enter trusted domains:"$HEIGHT $WIDTH 3>&1 1>&2 2>3)
	nextcloud.manual-install "$username" "$password"
	sleep 4
	nextcloud.occ config:system:set trusted_domains 1 --value="$trusted_domains"
	sleep 4
	nextcloud.enable-https self-signed

	if whiptail --title "Nextcloud Ports" --yesno "Do you wants to change HTTP/HTTPS ports?" $HEIGHT $WIDTH; then
		HTTP_PORT=$(whiptail --inputbox "Enter new HTTP-Port:" $HEIGHT $WIDTH 3>&1 1>&2 2>3)
		HTTPS_PORT=$(whiptail --inputbox "Enter new HTTPS-Port:" $HEIGHT $WIDTH 3>&1 1>&2 2>3)

		HTTP_PORT=${HTTP_PORT:-80}
		HTTPS_PORT=${HTTPS_PORT:-443}

		snap set nextcloud ports.http="$HTTP_PORT" ports.https="$HTTPS_PORT"
		snap restart nextcloud

		message_box "Successfully" "Change https/http to $HTTPS_PORT $HTTP_PORT ."
	else
		message_box "Default" "Keeping default ports (HTTP: 80, HTTPS: 443)."
		break
	fi
}

function install_packages() {
  if ! which wget whiptail curl zip unzip snapd >/dev/null 2>&1; then
    if which apt >/dev/null 2>&1; then
      apt update
      DEBIAN_FRONTEND=noninteractive apt install wget whiptail curl zip unzip snapd  -y
      return 0
    fi
    if which yum >/dev/null 2>&1; then
      yum makecache
      yum install epel-release -y || true
      yum install wget whiptail curl zip unzip snapd  -y
      return 0
    fi
    echo "OS is not supported!"
    return 1
  fi
}

install_packages

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

if [[ $? -eq 0 ]]; then
	echo "Package install successfully. Starting main-script..."
	sleep 2
	main_menu
else 
	echo "Failed to install packages."
	exit
fi


#main_menu
