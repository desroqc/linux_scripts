#!/bin/bash
#
# v1.0
#
# Ubuntu 18.04.4 LTS with zip package
# 2020-03-02
#
# Usage: ./bkp_system.sh -d /mnt/backup -k 4
# Description: Will create Zip file with a system backup inside /mnt/backup and keep the 4 most recents Zip file
#

# Date variable
backup_date_full=$(date +"%Y-%m-%d_%H-%M-%S")

# Get each argument
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -d|--destination)
      destination=$2
      shift 2
      ;;
    -k|--keep)
      keep=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Create the destination folder
mkdir -p $destination/$HOSTNAME

# Delete old backup but keep X number of versions ( order by date )
function cleanup {
  current_backup_count=$(ls -l $destination/$HOSTNAME/ | grep "zip" | wc -l)
  oldest_backup=$(ls $destination/$HOSTNAME/ | sort -n | head -1)
  echo "Cleanup: $current_backup_count out of $keep"
  if [[ $current_backup_count -ge $keep ]]; then
    echo "Cleanup: Deleting $destination/$HOSTNAME/$oldest_backup"
    rm $destination/$HOSTNAME/$oldest_backup
    cleanup
  else
    echo "Cleanup: OK"
  fi
}

# Get --container argument
bkpIFS="$IFS"
IFS=',()][' read -r -a container_list <<<"$container_list"
IFS="$bkpIFS"

# Backup cleanup ( if -k is used )
if [[ $keep != "" ]]; then
  cleanup
else
  echo "Cleanup: Skipping"
fi

# Files and folders to backup
zip "$destination/$HOSTNAME/system-$backup_date_full.zip" /etc/fstab
zip -r "$destination/$HOSTNAME/system-$backup_date_full.zip" /etc/default
zip -r "$destination/$HOSTNAME/system-$backup_date_full.zip" /etc/nginx
zip -r "$destination/$HOSTNAME/system-$backup_date_full.zip" /etc/ssh
zip -r "$destination/$HOSTNAME/system-$backup_date_full.zip" /etc/ufw
zip -r "$destination/$HOSTNAME/system-$backup_date_full.zip" /opt/docker
zip -r "$destination/$HOSTNAME/system-$backup_date_full.zip" /opt/script
crontab -l > /tmp/crontab.txt && zip "$destination/$HOSTNAME/system-$backup_date_full.zip" /tmp/crontab.txt