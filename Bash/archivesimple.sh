#!/bin/bash

# This script is used to create a new archive disk on a new server. It is
# intended to be run on the new server, and will create a new LUKS-encrypted
# partition on the new disk, format it with ext4, mount it, and copy the
# contents of the old archive disk to it. It will also create an index of the
# archive contents, and rsync the MySQL backups from the old server. It will
# then unmount the new disk and send an email to the sysadmin group to let them
# know the archive disk is ready to be swapped into the old server.
# Author: Xerxes

set -e

readonly TGTPRT="/dev/sdb1"
readonly FSTYPE="xfs"
readonly SOURCE="/mnt/shared"
readonly DEST="/mnt/archive"
readonly KEYUUID="UUID=12345678-1234-1234-1234-123456789012"
readonly KEYDEST="/mnt/usbkey"
readonly TMPDIR="$(mktemp -d)"
readonly TMPERR="${TMPDIR}/error.log"
readonly TMPOUT="${TMPDIR}/output.log"
readonly TGTLUKS="/dev/mapper/archive"

function log_write() {
  local message="$1"
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> /var/log/archive.log
}

function error() {
  local message="$1"
  printf "%s\n" "$message" >&2
  log_write "ERROR: $message"
  exit 1
}

function mount_key() {
  mount "$KEYUUID" "$KEYDEST"
}

function umount_key() {
  umount "$KEYDEST"
}

function create_luks() {
  if [[ -e "$TGTLUKS" ]]; then
    cryptsetup luksClose "$TGTLUKS"
  fi
  log_write "Setting up LUKS encryption on new partition"
  printf "Setting up LUKS encryption on new partition...\n"
  mount_key
  cryptsetup luksFormat "$TGTPRT" --key-file "$KEYDEST/passphrase.txt" > "$TMPERR" 2>&1
  cryptsetup luksOpen "$TGTPRT" "$(basename "$TGTLUKS")" --key-file "$KEYDEST/passphrase.txt" > "$TMPERR" 2>&1
  umount_key
  log_write "OK: Successfully set up LUKS encryption on new partition"
  printf "Done.\n"
}

function format_partition() {
  log_write "Formatting new partition with $FSTYPE filesystem"
printf "Formatting new partition with %s filesystem...\n" "$FSTYPE"
  mkfs -t "$FSTYPE" "$TGTLUKS" > "$TMPERR" 2>&1
  log_write "OK: Formatted new partition with $FSTYPE filesystem"
  printf "Done.\n"
}

function mount_partition() {
printf "Mounting new %s filesystem %s on %s...\n" "$FSTYPE" "$TGTLUKS" "$DEST"
  mount -t "$FSTYPE" "$TGTLUKS" "$DEST"
  if command -v restorecon > /dev/null; then
    restorecon -R "$DEST"
  fi
  umount "$DEST"
  mount -t "$FSTYPE" "$TGTLUKS" "$DEST"
  log_write "OK: Mounted new $FSTYPE filesystem $TGTLUKS on $DEST"
  printf "Done.\n"
}

function archive_data() {
printf "Archiving data from %s...\n" "$SOURCE"
  log_write "Archiving data from $SOURCE"
  tar -czf "$DEST/archive_$(date '+%Y%m%d').tar.gz" -C "$SOURCE" .
  sync
  log_write "OK: $SOURCE archived successfully"
  printf "Done.\n"
}

function create_index() {
  printf "Creating archive index file...\n"
  log_write "Creating archive index file"
  local index_dir="$SOURCE/archivelist"
  if [[ ! -d "$index_dir" ]]; then
    mkdir -p "$index_dir"
    chgrp sysadmin "$index_dir"
  fi
  ls -lR "$SOURCE" > "$index_dir/Archive_Index_$(date '+%Y.%m.%d').txt"
  sed -i 's/$/\r/' "$index_dir/Archive_Index_$(date '+%Y.%m.%d').txt"
  zip -9jq "$index_dir/Archive_Index_$(date '+%Y.%m.%d').txt.zip" "$index_dir/Archive_Index_$(date '+%Y.%m.%d').txt"
  rm "$index_dir/Archive_Index_$(date '+%Y.%m.%d').txt"
  log_write "OK: Created archive index file"
  printf "Done.\n"
}

function rsync_mysql() {
local yesterday
yesterday=$(date --date='yesterday' '+%Y_%m_%d')
  printf "Rsyncing yesterday's MySQL database backups from Fluffy01...\n"
  log_write "Rsyncing yesterday's MySQL database backups from Fluffy01"
  rsync -zarv --delete -e '/usr/bin/ssh -l root -i Identity' \
      --include="mysql_backups/" \
      --include="mysql_backup/" \
      --include="data/" \
      --include="$yesterday/" \
      --include="*.csh" \
      --include="*.csh~" \
      --include="*.bz2" \
      --include="*.gz" \
      --exclude="*" \
      root@fluffy01:/home2/mysql_backups "$DEST/fluffy01" > "$TMPOUT" 2>&1
    log_write "$(cat "$TMPOUT")"
    rm -f "$TMPOUT"
    log_write "OK: MySQL database backups on Fluffy01 rsynced successfully"
    printf "Done.\n"

    printf "Rsyncing yesterday's MySQL database backups from Fluffy02...\n"
    log_write "Rsyncing yesterday's MySQL database backups from Fluffy02"
    rsync -zarv --delete -e '/usr/bin/ssh -l root -i Identity' \
      --include="mysql_backups/" \
      --include="mysql_backup/" \
      --include="mysql_wherezit/" \
      --include="data/" \
      --include="$yesterday/" \
      --include="*.csh" \
      --include="*.csh~" \
      --include="*.bz2" \
      --include="*.gz" \
      --exclude="*" \
      root@fluffy02:/home/mysql_backups "$DEST/fluffy02" > "$TMPOUT" 2>&1
  log_write "$(cat "$TMPOUT")"
  rm -f "$TMPOUT"
  log_write "OK: MySQL database backups on Fluffy02 rsynced successfully"
  printf "Done.\n"
}

function disk_usage() {
  log_write "Disk space used by archive:"
  du -sh "$DEST"/*
}

function unmount_partition() {
  printf "Unmounting archive disk filesystem %s...\n" "$TGTLUKS"
  log_write "Unmounting archive disk filesystem $TGTLUKS"
  umount "$TGTLUKS"
  cryptsetup luksClose "$TGTLUKS"
  log_write "OK: Unmounted archive filesystem $TGTLUKS"
  printf "Done.\n"
}

function remove_mountpoints() {
  rmdir "$DEST" "$KEYDEST"
}

function send_email() {
  printf "Sending success email...\n"
  email "Archive backup successful on $(hostname)"
}

function main() {
  log_write start
  create_luks
  format_partition
  mount_partition
  archive_data
  create_index
  rsync_mysql
  disk_usage
  unmount_partition
  remove_mountpoints
  log_write "OK: Archive created successfully"
  log_write end
  send_email
}

sudo sh -c "$(declare -f main); main"
