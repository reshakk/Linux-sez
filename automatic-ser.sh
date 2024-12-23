#!/usr/bin/env bash

# ██▀███  ▓█████   ██████  ██░ ██  ▄▄▄       ██ ▄█▀ ██ ▄█▀
#▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▓██░ ██▒▒████▄     ██▄█▒  ██▄█▒ 
#▓██ ░▄█ ▒▒███   ░ ▓██▄   ▒██▀▀██░▒██  ▀█▄  ▓███▄░ ▓███▄░ 
#▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒░▓█ ░██ ░██▄▄▄▄██ ▓██ █▄ ▓██ █▄ 
#░██▓ ▒██▒░▒████▒▒██████▒▒░▓█▒░██▓ ▓█   ▓██▒▒██▒ █▄▒██▒ █▄
#░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒ ▒▒   ▓▒█░▒ ▒▒ ▓▒▒ ▒▒ ▓▒
#  ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░ ▒ ░▒░ ░  ▒   ▒▒ ░░ ░▒ ▒░░ ░▒ ▒░
#  ░░   ░    ░   ░  ░  ░   ░  ░░ ░  ░   ▒   ░ ░░ ░ ░ ░░ ░ 
#   ░        ░  ░      ░   ░  ░  ░      ░  ░░  ░   ░  ░   


# Define color codes

ERROR='\033[0;31m'
READ='\033[0;32m'
OUTPUT='\033[0;33m'
NOTE='\033[0;34m'
RESET='\033[0;39m'

echo -e "$NOTE Welcome to Reshakk's Ubuntu-server auto installer script! $RESET"
echo


#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
        echo -e "$ERROR Please run as root $RESET"
        exit
fi


read -p "Do you want to set up a new user and 'sshd_config'? (y/n) " sshdu
sshdu=${sshdu:-n}  # Default to 'n' if no input is given

read -p "Do you want to set up swap on 2G? (y/n) " swapu
swapu=${swapu:-n} 

read -p "Do you want to set knockd on server? (y/n) " knockdu
knockdu=${knockdu:-n}


# Function to execute a script from a URL
execute_script() {
    local script_url=$1
    if ! bash <(curl -sL "$script_url"); then
        echo "$ERROR Failed to execute script: $script_url $RESET"
    fi
}


# Execute scripts based on user input
[[ "$sshdu" == "y" ]] && execute_script "https://raw.githubusercontent.com/reshakk/Server-auto/master/sec-setting.sh"
[[ "$swapu" == "y" ]] && execute_script "https://raw.githubusercontent.com/reshakk/Server-auto/master/swap.sh"
[[ "$knockdu" == "y" ]] && execute_script "https://raw.githubusercontent.com/reshakk/Server-auto/master/start-knock.sh"
