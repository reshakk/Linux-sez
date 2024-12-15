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

set -e

echo "Welcome to Reshakk's Ubuntu-server auto installer script!"
echo


#Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
fi


read -p "Do you want to set up a new user and 'sshd_config'? (y/n) " sshdu
sshdu=${sshdu:-n}  # Default to 'n' if no input is given

read -p "Do you want to set up swap on 2G? (y/n, default: y) " swapu
swapu=${swapu:-n} 

read -p "Do you want to set knockd on server? (y/n, default: y) " knockdu
knockdu=${knockdu:-n}


# Function to execute a script from a URL
execute_script() {
    local script_url=$1
    if ! bash <(curl -sL "$script_url"); then
        echo "Failed to execute script: $script_url"
    fi
}


# Execute scripts based on user input
[[ "$sshdu" == "y" ]] && execute_script "https://raw.githubusercontent.com/reshakk/Server-auto/master/sec-setting.sh"
[[ "$swapu" == "y" ]] && execute_script "https://raw.githubusercontent.com/reshakk/Server-auto/master/swap.sh"
[[ "$knockdu" == "y" ]] && execute_script "https://raw.githubusercontent.com/reshakk/Server-auto/master/start-knock.sh"
