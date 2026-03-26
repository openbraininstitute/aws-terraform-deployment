#!/bin/bash

logger "start of user_setup script"

# to be removed, for testing with serial access
echo "ubuntu:blabla" | chpasswd
passwd -u ubuntu

logger "ubuntu user changed"

sudo systemctl disable ufw
sudo systemctl stop ufw

logger "ufw disabled"


sudo apt install -y git lsof rsync tmux vim wget zsh openssh-server

logger "installed certain packages"

# Enable and start SSH daemon
systemctl enable ssh
systemctl start ssh

logger "ssh was enabled"


sudo apt update && sudo apt upgrade -y

logger "apt update done"

