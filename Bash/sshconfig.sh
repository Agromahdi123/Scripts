#!/bin/bash

# Prompt user for variables
read -p "Enter the alias: " alias
read -p "Enter the hostname: " hostname
read -p "Enter the IP address: " ip
read -p "Enter the username: " username
read -p "Enter the port number: " port
read -p "Enter the location of the identity file: " identity_file

# Generate SSH config file
echo "Host $alias
    HostName $hostname
    User $username
    Port $port
    HostKeyAlias $alias
    CheckHostIP no
    IdentityFile $identity_file" >> ~/.ssh/config
    

echo "SSH config file updated successfully!"
