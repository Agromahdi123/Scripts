#!/bin/bash
#
# Nightly rsync backup script for multiple servers
#
# NOTE: In order for this script to work without requesting
# passwords, you MUST setup ssh keys that allows the crontab
# user to log in on the remote machine as the designated
# user without a password.  Just fire up ssh-keygen and
# build a public/private key.  Copy the public part to the
# remote SERVER and stuff it into ~/.ssh/authorized_keys
# You must also configure roots ssh config to allow login with just
# server alias.
# This script is designed to be run as a cron job by root.
# You must have a configuration file for each server in
# /etc/rsync-backup.  The configuration file must be named
# <server>.conf.  See the example configuration file for
# details.
# Author:  Xerxes
# Date:    2023-10-07

set -euo pipefail  # Enable strict error checking

# Define functions
run_rsync() {
    local server="$1"
    local source_dir="$2"
    local log_file="$3"
    local rsync_args="$4"
    local exclude_file="/mnt/archive/$server/rsyncexclude"
    # Create exclude file if it doesn't exist
    if [ ! -f "$exclude_file" ]; then
        echo "# Recommended exclusions for server backup" > "$exclude_file"
        echo "/dev/*" >> "$exclude_file"
        echo "/proc/*" >> "$exclude_file"
        echo "/sys/*" >> "$exclude_file"
        echo "/tmp/*" >> "$exclude_file"
        echo "/run/*" >> "$exclude_file"
        echo "/mnt/*" >> "$exclude_file"
        echo "/media/*" >> "$exclude_file"
        echo "/lost+found" >> "$exclude_file"
        echo "/var/cache/*" >> "$exclude_file"
        echo "/var/lock/*" >> "$exclude_file"
        echo "/var/run/*" >> "$exclude_file"
        echo "/var/tmp/*" >> "$exclude_file"
        echo "/boot/*" >> "$exclude_file"
    fi

    # Check if source directory exists
    if ! ssh "$server" "[ -d \"$source_dir\" ]"; then
        echo "Source directory $source_dir does not exist on $server"
        return 1
    fi

    # Run rsync command with error checking
    local retries=0
    while true; do
        if "$RSYNC" "$rsync_args" --exclude-from="$exclude_file" -e '/usr/bin/ssh' "$server:$source_dir" . >> "$log_file" 2>&1; then
            echo "Rsync of $source_dir on $server completed successfully"; date;
            return 0
        else
            echo "Rsync of $source_dir on $server failed"; date;
            retries=$((retries+1))
            if [ $retries -ge 3 ]; then
                echo "Rsync of $source_dir on $server failed after $retries retries"
                return 1
            fi
            sleep 60
        fi
    done
}

send_email() {
    local server="$1"
    local log_file="$2"
    local tmp_log_file="/tmp/rsync.log.$$"
    local email_subject="Cron - Rsync log - Nightly backup of $server"
    local email_body="Nightly rsync of $server completed on $(date). See attached log file for details."
    local email_from="rsync-backup@$(hostname)"
    local email_to="$EMAIL_ADDRESS"
    echo "$email_body" > "$tmp_log_file"

    # Check the size of the log file and compress it if necessary
    local log_size=$(stat -c%s "$log_file")
    if [ "$log_size" -gt 25000000 ]; then
        gzip "$log_file"
        log_file="$log_file.gz"
        email_subject="$email_subject (compressed)"
    fi

    # Send the email with the log file attached
    { echo "$email_body" | cat - "$log_file" | mail -s "$email_subject" -r "$email_from" -a "$log_file" "$email_to"; } >> "$log_file"
    rm "$tmp_log_file"
}

# Load configuration files and loop through servers
for conf_file in /etc/rsync-backup/*.conf; do
    source "$conf_file" || { echo "Error: Failed to load configuration file $conf_file"; exit 1; } # Load configuration variables
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR" || { echo "Error: Failed to create backup directory $BACKUP_DIR"; exit 1; }  # Create backup directory if it doesn't exist
    fi
    cd "$BACKUP_DIR" || { echo "Error: Failed to change to backup directory $BACKUP_DIR"; exit 1; }  # Change to backup directory   
    
# Clear the existing log file
    # Run rsync and log results in the background
    run_rsync "$SERVER" "/" "root.log" "$RSYNC_ARGS" &

done

# Wait for all background processes to finish
wait

# Send email with log file for each server
for conf_file in /etc/rsync-backup/*.conf; do
    source "$conf_file" || { echo "Error: Failed to load configuration file $conf_file"; exit 1; } # Load configuration variables
    send_email "$SERVER" "root.log" || { echo "Error: Failed to send email for server $SERVER"; exit 1; }
done