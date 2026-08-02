#!/usr/bin/env bash

# New users
# sudo adduser <username>
# Grant the new user sudo privileges:
#   sudo visudo
#   Add line: <username> ALL=(ALL:ALL) ALL
# Change to that user:
#   su - <username>

# Change server name:
#   sudo hostname new-name
#   or edit /etc/hostname and add 127.0.1.1 new-name to /etc/hosts

# System update
sudo apt-get update
sudo apt-get install -y build-essential
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# Keep SSH sessions alive
#   Edit /etc/ssh/ssh_config, add under Host *:
#   ServerAliveInterval 120
sudo service ssh restart

# Fix perl locale complaints
#   Add to /etc/environment:
#   export LANGUAGE=en_US.UTF-8
#   export LC_ALL=en_US.UTF-8
#   export LANG=en_US.UTF-8
#   export LC_TYPE=en_US.UTF-8

# Basics
sudo apt-get install -y git github-backup cmake
sudo apt-get install -y awscli
complete -C aws_completer aws
