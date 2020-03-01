#!/bin/bash
#
# v1.0
#
# Ubuntu 18.04.4 LTS + LXC/LXD
# 2020-03-02
#
# Usage: ./bkp_lxc -d /mnt/backup/lxc -k 4
# Description: Backup all running LXC container to /mnt/backup/lxc/$HOSTNAME and keep the 4 most recent Tarball
#
# Usage: ./bkp_lxc -c container_name -d /lxd/backup/lxc -k 4
# Description: Backup a single LXC container to /mnt/backup/lxc/$HOSTNAME and keep the 4 most recent Tarball
#
# Usage: ./bkp_lxc -c [container_name1,container_name2,container_name3] -d /lxd/backup/lxc -k 4
# Description: Backup every specified LXC container to /mnt/backup/lxc/$HOSTNAME and keep the 4 most recent Tarball
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
    -c|--container)
      container_list=$2
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

# Delete old backup
function cleanup {
  current_backup_count=$(ls -l $destination/$HOSTNAME/$1/ | grep "tar.gz" | wc -l)
  oldest_backup=$(ls $destination/$HOSTNAME/$1/ | sort -n | head -1)
  echo "Cleanup: $current_backup_count out of $keep"
  if [[ $current_backup_count -ge $keep ]]; then
    echo "Cleanup: Deleting $destination/$HOSTNAME/$1/$oldest_backup"
    rm $destination/$HOSTNAME/$1/$oldest_backup
    cleanup $1
  else
    echo "Cleanup: OK"
  fi
}

# Get --container argument
bkpIFS="$IFS"
IFS=',()][' read -r -a container_list <<<"$container_list"
IFS="$bkpIFS"

# Backup selected containers
if [[ ${container_list[@]} != "" ]]; then
  for i in ${container_list[@]}; do
    echo "Backup: Backing up $i to $destination/$HOSTNAME/$i/$i-$backup_date_full.tar.gz"
    if [[ $keep != "" ]]; then
      cleanup $i
    else
      echo "Cleanup: Skipping"
    fi
    echo "* * * Stopping $i - $(date) * * *"
    lxc stop $i
    echo "* * * Backing up /var/lib/lxd/containers/$i/rootfs to $destination/$HOSTNAME/$i/$i-$backup_date_full.tar.gz - $(date) * * *"
    mkdir -p $destination/$HOSTNAME/$i
    cd /var/lib/lxd/containers/$i
    tar cpfz $destination/$HOSTNAME/$i/$i-$backup_date_full.tar.gz rootfs
    echo "* * * Backing up $i profile if found - $(date) * * *"
    lxc profile show $i && lxc profile show $i > $destination/$HOSTNAME/$i.profile
    echo "* * * Starting $i - $(date) * * *"
    lxc start $i
  done
# Backup all running containers
else
  # container_list=$(lxc list -c ns | cut -d '|' -f 2)
  echo "Backup: Backing up all running containers to $destination/$HOSTNAME/"

  # List all running containers
  lxc_list=$(lxc list -c ns | grep "RUNNING" | cut -d '|' -f 2)

  # Backup all running containers
  for i in $lxc_list; do
    echo "* * * Stopping $i - $(date) * * *"
    if [[ $keep != "" ]]; then
      cleanup $i
    else
      echo "Cleanup: Skipping"
    fi
    lxc stop $i
    echo "* * * Backing up /var/lib/lxd/containers/$i/rootfs to $destination/$HOSTNAME/$i/$i-$backup_date_full.tar.gz - $(date) * * *"
    mkdir -p $destination/$HOSTNAME/$i
    cd /var/lib/lxd/containers/$i
    tar cpfz $destination/$HOSTNAME/$i/$i-$backup_date_full.tar.gz rootfs
    echo "* * * Backing up $i profile if found - $(date) * * *"
    lxc profile show $i && lxc profile show $i > $destination/$HOSTNAME/$i.profile
    echo "* * * Starting $i - $(date) * * *"
    lxc start $i
  done
fi

# Backing up default profile
echo "* * * Backing up default profile - $(date) * * *"
lxc profile show default > $destination/$HOSTNAME/default.profile

