#!/bin/bash
# this script will create a user on the local system
# you will be prompted to enter the username (login), the person name, and a password
# the username, password, and host for the account will be displayed
# Author: Xerxes 10/12/2023



# make sure the script is being executed with superuser privileges
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or as root.'
  exit 1
fi

# Function to validate integer input
function validate_integer_input {
    local input=$1
    if [[ ! $input =~ ^[0-9]+$ ]]; then
        echo "Error: Input must be a positive integer."
        exit 1
    fi
}

# Function to validate password policy input
function validate_password_policy_input {
    local input=$1
    if [[ ! $input =~ ^[0-9]+$ ]]; then
        echo "Error: Input must be a positive integer."
        exit 1
    elif [[ $input -lt 1 || $input -gt 365 ]]; then
        echo "Error: Input must be between 1 and 365 days."
        exit 1
    fi
}

# Function to validate password length input
function validate_password_length_input {
    local input=$1
    if [[ ! $input =~ ^[0-9]+$ ]]; then
        echo "Error: Input must be a positive integer."
        exit 1
    elif [[ $input -lt 8 || $input -gt 32 ]]; then
        echo "Error: Input must be between 8 and 32 characters."
        exit 1
    fi
}

# Function to validate username input
function validate_username_input {
    local input=$1
    if [[ ! $input =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        echo "Error: Username must start with a lowercase letter or underscore, and can only contain lowercase letters, digits, hyphens, and underscores."
        exit 1
    fi
}

# Prompt the user for the number of users to create
read -p "Enter the number of users to create (default: 1): " num_users
num_users=${num_users:-1}
validate_integer_input $num_users

# Prompt the user for password policy expiration
read -p "Enter the password policy expiration in days (default: 90): " password_policy_expiration
password_policy_expiration=${password_policy_expiration:-90}
validate_password_policy_input $password_policy_expiration

# Prompt the user for password policy minimum length
read -p "Enter the password policy minimum length (default: 8): " password_policy_min_length
password_policy_min_length=${password_policy_min_length:-8}
validate_password_length_input $password_policy_min_length

# Loop through and create each user
for ((i=1; i<=num_users; i++)); do

    # Prompt the user for the username
    read -p "Enter the username for user$i: " username
    validate_username_input $username

    # Prompt the user for whether to generate a random password or not
    read -p "Generate a random password for user$i? (y/n, default: y): " generate_password
    generate_password=${generate_password:-y}

    if [ "$generate_password" == "y" ]; then
        # Generate a random password
        password=$(openssl rand -base64 12)
    else
        # Prompt the user for the password
        read -p "Enter the password for user$i: " password
    fi

    # Prompt the user for the group name
    read -p "Enter the group name for user$i (default: users): " groupname
    groupname=${groupname:-users}

    # Prompt the user for the shell
    read -p "Enter the shell for user$i (default: /bin/bash): " shell
    shell=${shell:-/bin/bash}

    # Prompt the user for the home directory
    read -p "Enter the home directory for user$i (default: /home/$username): " homedir
    homedir=${homedir:-/home/$username}

    # Prompt the user for the comment
    read -p "Enter the comment for user$i: " comment

    # Create the user with the generated password, group, shell, home directory, and comment
    useradd -m \
            -g $groupname \
            -s $shell \
            -d $homedir \
            -c "$comment" \
            $username \
            -p $(openssl passwd -1 $password) \
            -e $(date -d "+$password_policy_expiration days" +%Y-%m-%d) \
            -f $password_policy_min_length
            
    # Print out the username and password for the user
    echo "User $username created with password: $password"
done
