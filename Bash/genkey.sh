#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Prompt the user to input the username, target server and location to save the key
read -p "Enter your username: " username
read -p "Enter your server address: " target_server
read -p "Enter the location to save the key: " key_location

# Generate the SSH key
ssh-keygen -t rsa -b 8192 -C "$username@$target_server" -f "$key_location"

# Upload the public key to the target server
ssh-copy-id -i "$key_location.pub" "$username@$target_server"

# Prompt the user if they want to add more servers
while true; do
    read -p "Do you want to add more servers? (y/n): " yn
    case $yn in
        [Yy]* ) 
            read -p "Enter your server address: " target_server
            read -p "Enter the location to save the key: " key_location
            ssh-keygen -t rsa -b 8192 -C "$username@$target_server" -f "$key_location"
            ssh-copy-id -i "$key_location.pub" "$username@$target_server"
            ;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
