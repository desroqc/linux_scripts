#!/bin/bash
#
# v1.0
#
# Ubuntu 18.04.4 LTS with zip package
# 2020-03-02
#
# Usage: ./upd8_docker.sh -d /mnt/backup -k 4
# Description: Run every update.sh inside /opt/docker/*
#
# Usage: ./upd8_docker.sh -c portainer -d /mnt/backup -k 4
# Description: Run ./opt/docker/portainer/update.sh
#
# Usage: ./upd8_docker.sh -c [portainer,bitwarden] -d /mnt/backup -k 4
# Description: Run every update.sh inside /opt/docker/portainer and /opt/docker/bitwarden
#



#
# TODO
# For each folder inside /opt/docker or selected item run ./update.sh if exist
#

