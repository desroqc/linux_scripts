#!/bin/bash
#
# v1.0
#
# Ubuntu 18.04.4 LTS + LXC/LXD
# 2020-03-02
#
# Usage: ./upd8_lxc --restart
# Description: Update all running containers and restart them at the end
#
# Usage: ./upd8_lxc -c container_name --restart
# Description: Update selected container and restart it at the end
#
# Usage: ./upd8_lxc -c [container_name1,container_name2,container_name3] --restart
# Description: Update selected containers and restart them at the end
#

# Get each argument
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -c|--container)
      container_list=$2
      shift 2
      ;;
    -r|--restart)
      restart=$2
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

bkpIFS="$IFS"
IFS=',()][' read -r -a container_list <<<"$container_list"
IFS="$bkpIFS"

# Update selected containers
if [[ ${container_list[@]} != "" ]]; then
  for i in ${container_list[@]}; do
    echo "* * * Updating $i - $(date) * * *"
    lxc exec $i -- apt update
    lxc exec $i -- apt upgrade -y
    echo "* * * Cleaning up $i - $(date) * * *"
    lxc exec $i -- rm -rf /var/lib/apt/lists/*
    lxc exec $i -- apt clean
    if [[ $restart != "" ]]; then
      echo "* * * Restarting $i - $(date) * * *"
      lxc restart $i
    fi
    echo "* * * Done - $(date) * * *"
  done
else
  echo "Update: Updating all running containers"

  # List all running containers
  running_containers=$(lxc list -c ns | grep "RUNNING" | cut -d '|' -f 2)

  # Update all running containers
  for i in $running_containers; do
    echo "* * * Updating $i - $(date) * * *"
    lxc exec $i -- apt update
    lxc exec $i -- apt upgrade -y
    echo "* * * Cleaning up $i - $(date) * * *"
    lxc exec $i -- rm -rf /var/lib/apt/lists/*
    lxc exec $i -- apt clean
    if [[ $restart != "" ]]; then
      echo "* * * Restarting $i - $(date) * * *"
      lxc restart $i
    fi
    echo "* * * Done - $(date) * * *"
  done
fi