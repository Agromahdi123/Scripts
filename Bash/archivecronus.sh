#!/bin/bash


# Define variables
SOURCE="/path/to/source"
DEST="/path/to/destination"
DEVPATH="/dev/sdb1"
KEYUUID="/dev/sdc1"
KEYDEST="/mnt/usb"
TGTPRT="1"
TGTLUKS="/dev/mapper/luks"
FSTYPE="ext4"
DISK_MINSIZE="100"

# Define functions
log_write () {
  # Write message to log file
  if [ -f "${LOG}" ]; then
    echo "`date +%F\ %T\:` ${1}" >> "${LOG}"
  else
    echo "`date +%F\ %T\:` ${1}" >> "${TMPLOG}"
  fi
}

email () {
  # Send email with message
  cat "${TMPLOG}" | mail -s "${1}" "${EMAIL_RCPTS}"
}

email_err () {
  # Send email with error message and details
  (printf "%b" "Error details:\n\n" && cat "${TMPERR}" && echo "" && cat "${TMPLOG}") | mail -s "${1}" "${EMAIL_RCPTS}"
}

error () {
  # Log error message, print to stderr, send email with error details, and exit with error code
  log_write "${1}"
  printf "%b" "\n${1}\n\n" >&2
  printf "%b" "Error details:\n\n`cat ${TMPERR}`\n\n"
  log_write end
  email_err "Archive backup FAILED on `hostname`"
  exit 1
}

cleanup () {
  # Remove temporary files
  for file in "${TMPLOG}" "${TMPERR}" "${TMPFDK}" "${TMPOUT}"; do
    rm -f "${file}"
  done
}

# Clean up temporary files upon exit
trap cleanup EXIT

# Check that this script is being run as root
if [ $EUID -ne 0 ]; then
  ERRSTR="`basename $0`: ERROR: This script must be run as root."
  printf "%b" "\n${ERRSTR}\n\n" >&2
  printf "%b" "\n${ERRSTR}\n\n" | mail -s "Archive backup FAILED on `hostname`" "${EMAIL_RCPTS}"
  exit 1
fi

# Begin logging
log_write begin

# Start archive
log_write "Starting archive"
echo "Starting archive on `date \"+%a %b %d, %Y @ %r\"`"

# Check if archiving disk is inserted inside the hot-swap bay
if [ ! -e "${DEVPATH}" ]; then
  ls "${DEVPATH}" 2>"${TMPERR}"
  error "ERROR: Archive disk is not inserted in the hot-swap drive bay."
fi

# Check if the USB drive containing the encryption passphrase is inserted
if [ ! -b "${KEYUUID}" ]; then
  ls "${KEYUUID}" 2>"${TMPERR}"
  error "ERROR: The USB encryption passphrase drive is not inserted"
fi

# Let everyone know the name of the device we are using for archiving
log_write "Using device ${DEST}"
printf "%b" "\nUsing device ${DEST}\n"

# Make sure the disk is larger than the minimum size defined in the variable
# DISK_MINSIZE
let DISK_CURSIZE=$(fdisk -l "${DEST}" | sed '/^$/d' | sed '1!d' | cut -d' ' -f5)/1000000000
if [ ${DISK_CURSIZE} -lt ${DISK_MINSIZE} ]; then
  error "ERROR: The archive disk is smaller than the currently configured minimum disk size of ${DISK_MINSIZE} GB."
fi

# Check if the disk is already partitioned; there may already be data written on
# the drive if it is already partitioned so stop here on error
log_write "Checking if partition table already exists on disk"
if [ $(grep -c "`basename ${DEST}`[0-9]" /proc/partitions) -gt 0 ]; then
  fdisk -l "${DEST}" > "${TMPERR}"
  error "ERROR: The archive disk already contains an active partition table.  Archive disks must be unpartitioned before archival."
else
  log_write "OK: No partition table found on disk"
fi

# Partition the disk.  The following commands are piped to the fdisk program
# and the comments are removed using the following 'sed' command.
log_write "Creating new msdos partition table"
printf "%b" "Creating new partition table..."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF > "${TMPFDK}"
  n # Create a new partition
  p # Primary partition
  1 # Partition number 1
    # Default - start at beginning of disk
    # Default - extend partition to end of disk
  w # Write the partition table
  q # Quit fdisk
EOF
((cat "${TMPFDK}" | fdisk "${DEST}" >/dev/null 2>"${TMPERR}" && \
sleep 20) && \
(log_write "OK: Created new partition table" && printf "%b" "DONE\n")) || \
error "ERROR: Error creating partition table."

# Create mountpoints
mkdir -p "${DEST}" "${KEYDEST}" 2>"${TMPERR}" || error "ERROR: Error creating mountpoints."

# Encrypt the partition using the encryption key on the USB drive
if [ -e "${TGTLUKS}" ]; then
    cryptsetup luksClose "${TGTLUKS}"
fi
log_write "Setting up LUKS encryption on new partition"
printf "%b" "Setting up LUKS encryption on new partition..."
(mount "${KEYUUID}" "${KEYDEST}" 2>"${TMPERR}" && \
cat "${KEYDEST}/passphrase.txt" | cryptsetup luksFormat "${DEST}${TGTPRT}" --key-file - 2>"${TMPERR}" 1>"${TMPERR}" && \
cat "${KEYDEST}/passphrase.txt" | cryptsetup luksOpen "${DEST}${TGTPRT}" `basename "${TGTLUKS}"` --key-file - 2>"${TMPERR}" 1>"${TMPERR}" && \
umount "${KEYDEST}" 2>"${TMPERR}" && \
log_write "OK: Successfully set up LUKS encryption on new partition" && \
printf "%b" "DONE\n") || \
error "ERROR: Error setting up LUKS encryption on ${DEST}${TGTPRT}."

# Format the new partition, using the filesystem format defined in the FSTYPE
# variable
log_write "Formatting new partition with ${FSTYPE} filesystem"
printf "%b" "Formatting new partition with ${FSTYPE} filesystem..."
(mkfs -t "${FSTYPE}" "${TGTLUKS}" 2>"${TMPERR}" 1>"${TMPERR}" && \
log_write "OK: Formatted new partition with ${FSTYPE} filesystem" && \
printf "%b" "DONE\n") || \
error "ERROR: Could not create ${FSTYPE} filesystem on archive disk."

# Mount the new archive filesystem and fix SELinux label warnings
printf "%b" "Mounting new ${FSTYPE} filesystem ${TGTLUKS} on ${DEST}..."
((mount -t "${FSTYPE}" "${TGTLUKS}" "${DEST}" 2>"${TMPERR}" && \
if [ $(which restorecon) ]; then
  restorecon -R "${DEST}" 2>"${TMPERR}"
fi && \
umount "${DEST}" 2>"${TMPERR}" && \
mount -t "${FSTYPE}" "${TGTLUKS}" "${DEST}" 2>"${TMPERR}") && \
log_write "OK: Mounted new ${FSTYPE} filesystem ${TGTLUKS} on ${DEST}" && \
printf "%b" "DONE\n") || \
error "ERROR: Could not mount new partition ${TGTLUKS} on ${DEST}"

# Copy everything from $SOURCE to $DEST
printf "%b" "Archiving data from ${SOURCE}..."
log_write "Archiving data from ${SOURCE}"
(/usr/bin/rsync -a ${SOURCE} ${DEST} 2>${TMPERR} && \
sync && \
log_write "OK: ${SOURCE} archived successfully" && \
printf "%b" "DONE\n") || \
error "ERROR: Error encountered while copying data from ${SOURCE} to ${DEST}"

# Create the archive index file
printf "%b" "Creating archive index file..."
log_write "Creating archive index file"
if [ ! -d ${SOURCE}/archivelist ]; then
  (mkdir -p ${SOURCE}/archivelist 2>${TMPERR} && chgrp sysadmin ${SOURCE}/archivelist 2>${TMPERR}) || \
  error "ERROR: Error creating or assigning group permissions to ${SOURCE}/archivelist\""
fi
(ls -lR ${SOURCE} > ${SOURCE}/archivelist/"Archive_Index_`date +%Y.%m.%d`.txt" && \
sed -i 's/$/\r/' ${SOURCE}/archivelist/"Archive_Index_`date +%Y.%m.%d`.txt" && \
zip -9jq ${SOURCE}/archivelist/"Archive_Index_`date +%Y.%m.%d`.txt.zip" ${SOURCE}/archivelist/"Archive_Index_`date +%Y.%m.%d`.txt" 2>${TMPERR} && \
/bin/rm ${SOURCE}/archivelist/"Archive_Index_`date +%Y.%m.%d`.txt" 2>${TMPERR} && \
log_write "OK: Created archive index file" && \
printf "%b" "DONE\n") || \
error "ERROR: Error creating archive index file"

# Rsync yesterday's copy of the MySQL database backups on Fluffy01 to the archive disk
printf "%b" "Rsyncing yesterday's MySQL database backups from Fluffy01..."
log_write "Rsyncing yesterday's MySQL database backups from Fluffy01"
rsync -zarv -F --include="mysql_backups/" --include="mysql_backup/" --include="data/" --include="`date --date='yesterday' +%Y_%m_%d`/" --include="*.csh" --include="*.csh~" --include="*.bz2" --include="*.gz" --exclude="*" root@fluffy01:/mnt/SQLBackups fluffy01 ${DEST}/fluffy01 1>${TMPOUT} 2>1 && \
log_write "$(cat ${TMPOUT})"
rm -f ${TMPOUT}
log_write "OK: MySQL database backups on Fluffy01 rsynced successfully" && \
printf "%b" "DONE\n" || \
error "ERROR: Error during rsync of MySQL database backups from Fluffy01"


# Rsync yesterday's copy of the MySQL database backups on Fluffy02 to the archive disk
printf "%b" "Rsyncing yesterday's MySQL database backups from Fluffy02..."
log_write "Rsyncing yesterday's MySQL database backups from Fluffy02"
rsync -zarv -F --include="mysql_backups/" --include="mysql_backup/" --include="mysql_wherezit/" --include="data/" --include="`date --date='yesterday' +%Y_%m_%d`/" --include="*.csh" --include="*.csh~" --include="*.bz2" --include="*.gz" --exclude="*" root@fluffy02:/home/mysql_backups ${DEST}/fluffy02 1>${TMPOUT} 2>1 && \
log_write "$(cat ${TMPOUT})"
rm -f ${TMPOUT}
log_write "OK: MySQL database backups on Fluffy02 rsynced successfully" && \
printf "%b" "DONE\n" || \
error "ERROR: Error during rsync of MySQL database backups from Fluffy02"

# Run a du to get a feeling of the directory sizes on the archive disk
log_write "Disk space used by archive:"
log_write "$(du -sh ${DEST}/*)"

# Unmount the archive disk filesystem
printf "%b" "Unmounting archive disk filesystem ${TGTLUKS}..."
log_write "Unmounting archive disk filesystem ${TGTLUKS}"
(umount ${TGTLUKS} 2>${TMPERR} 1>${TMPERR} && \
cryptsetup luksClose ${TGTLUKS} 2>${TMPERR} 1>${TMPERR} && \
log_write "OK: Unmounted archive filesystem ${TGTLUKS}" && \
printf "%b" "DONE\n") || \
error "ERROR: Couldn't unmount archive disk filesystem ${TGTLUKS}"

# Remove mountpoints
rmdir ${DEST} ${KEYDEST}

## Write-protect the archive partition on the disk (write protecting the entire
## drive didn't seem to work during testing?)  If the partition itself is write
## -protected, effectively the entire disk is as well.
printf "%b" "Write-protecting the partition ${TGTDEV}${TGTPRT}..."
log_write "Write-protecting the partition ${TGTDEV}${TGTPRT}"
(hdparm -r1 ${TGTDEV}${TGTPRT} 1>/dev/null 2>${TMPERR} && \
log_write "OK: ${TGTDEV}${TGTPRT} write-protected" && \
printf "%b" "DONE\n") || \
error "ERROR: Failed to write-protect ${TGTDEV}${TGTPRT}"

# End logging on a successful note if everything went as planned
log_write "OK: Archive created successfully"
log_write end


# Send a success email
email "Archive backup successful on `hostname`"
