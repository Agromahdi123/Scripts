#!/bin/bash
# This script will backup all MySQL databases on the server
# This script needs a  /etc/mysql-backup.conf file with the following variables
# BACKUP_DIR="/path/to/backup/directory"
# MYSQL_CNF="/path/to/.my.cnf"
# EMAIL_ADDRESS="email@address"
# RETENTION_DAYS=45
# This script assumes that you have a /root/.my.cnf file with MySQL credentials
# This script assumes that you have pigz installed for compression
# This script assumes that you have mailutils installed for sending email
# This script should be run as root in a cronjob
# This script should be run on the MySQL server itself
# This script should be run at a time when MySQL is not under heavy load
# This script should run nightly with a cronjob at midnight
# 0 0 * * * /root/mysql_backup.sh
# Author - Xerxes

# Load configuration file
source /etc/mysql-backup.conf

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create log file with datestamp
LOG_FILE="$BACKUP_DIR"/mysql_backup_dump_$(date +%Y_%m_%d).log
touch "$LOG_FILE"

# Define functions
log() {
  echo "$(date "+%Y-%m-%d %H:%M:%S") $1" >> "$LOG_FILE"
}

backup_database() {
  local db=$1
  # Log the start of the backup for this database
  log "Dumping database: $db"
  # Create a backup of the database and compress it using pigz
  mysqldump --defaults-extra-file="$MYSQL_CNF" --opt --quick "$db" | pigz > "$BACKUP_DIR"/"$db".sql.gz
}

delete_old_backups() {
  # cd into the dir above $BACKUP_DIR
  cd "$(dirname "$BACKUP_DIR")" || exit
  # find all folders older than FOLDERS_TO_REMOVE days and delete them
  find "$(basename "$BACKUP_DIR")" -type d -mtime +"$RETENTION_DAYS" -exec rm -rf {} \;
}

# Log start of script
log "Starting backup script"

# Flush tables with read lock
mysql --defaults-extra-file="$MYSQL_CNF" -e "FLUSH TABLES WITH READ LOCK;"

# Loop through each database and create a backup
for db in $(mysql --defaults-extra-file="$MYSQL_CNF" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
do
  # Exclude system databases and tables
  if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
    backup_database "$db"
  fi
done

# Unlock tables
mysql --defaults-extra-file="$MYSQL_CNF" -e "UNLOCK TABLES;"

# Delete old backups
delete_old_backups

# Log end of script
log "Backup script completed"

# Email log file
if [ -f "$LOG_FILE" ]; then
  mail -s "Backup Log" "$EMAIL_ADDRESS" < "$LOG_FILE"
fi
