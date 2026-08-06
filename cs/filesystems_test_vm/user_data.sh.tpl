#!/bin/bash

# to be able to ssh as ubuntu user
sudo mkdir -p /home/ubuntu/.ssh/
sudo chown -R ubuntu:ubuntu /home/ubuntu/
sudo echo "${CS_SSH_KEY}" > /home/ubuntu/.ssh/authorized_keys
# Gianluca
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTQQu/jmTIhy7MjfoOlW6pqgjKpUa4r86UKlME7Tu0/l46xcmvnu64SvE99rLNUolNXdbv7PcnW/yzZpQery4ZCUtAzHLpPZQomu5v3AGa60JGXHRqtKu6ogv83VLgbsoEOPW50+WeBxJJYdrHq6kwc4AwFHlG1L8OsAj/b41HH530nAH7ytFcd8Z5JbUeXbvvT4Eouu+BUuSxvdq5Heq4G4OoYTLc9k+Eby4rjzTv1y5cn6nEmkX/fxhEs6ac+QIyyx1DyUD4LuSRvnpmUrSDcpVtHu61vJzTktVqbylU7J5GcBV5RDoAoOm/WnS3thNbWa3Y//x57OVgUCYd9JLM83zLbanaVPGwIoO77uWfmarKOnmLC7ycdr1B9ZPtZog0HyOh7qT7zXe4PCos3BVEUkQbOfXtXpU9pfJ8ce6LG6T+CUdkc8BHBlxVitsT2m+0kQr9LbilBJcw1sWyHMv5N984q9TQfz3IuX1sMtnVMEVe45TNT6M7goBJqdJsaatiunN7B19EVw1mtvQ58wOhHuA9GBIFWbQ5KJb1vK/JXsyjeE1CCa2oKoIAJOJgxwPnmvjGBnuIiP61b+fRo8UVfwXW+KdD1drgoC4y2D8NfdfvPip/atFnPKciWL9NK6Ur1CXNHilrDeKVTG4T2Pk1/iE0FdCTblmvoCO7No92VQ== gianluca.ficarelli@epfl.ch" >> /home/ubuntu/.ssh/authorized_keys
# Jean-Denis
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7ODbkDNLlwCDdhQLQLR7Gz6wVj3k+gU8Hzz6MMHxauwA/lW35KnWjxFplSFgwNmwc1SCfxbwQQiiN3c4EIO9FOYtsjefa9jaeTwUIiOhI48AAf6VXPNVOpugi+zH+emdMEHyIeCEG+aV96gEcugXkAdkOz6U6kBoujqTNmh5vlCFBhzEJ2xOCynCdlc0iqpoASVjNcS6VDNi6V4/TLVvE7rg/py/nnzDM0/AfQLMUn+noTDIfQrp1/B8GgedxCuYveOcS+cPvwJD2YkV8HYfBfqo8R/cDl4qYt3+1aY6cIDDVhDUniaG55fPZqNHm6G2RS5rRcpnT20pja9uPLIkxZm6io3rbQNFM1N3ATROtea9olpZcmgpSbcRvoh+Jua5to1YKDYOqTX61jCobVqSc0tYeV1k02wz3Yc86asOtglEukw9KJVaCI4sTDi7/1L9pS2dDU3WekXvf3idfI8uk25qbG3iL60bAC2HIVskeGxe0i76BqhtAlUSVk8tjwzKDQHMIJRWDH4UoR1MYnmJmBlfBixPJ3563u+K+Gqtj7Tyvvb0r5jbmpYMn6vvq/HhesieTy0aEeRp6qyqVMrHuVhIzr6wLKPLqdi4/EkuPGQgSAziHfEb0ZAXU+d0hryTR8AWiABQJymi5MKKZMRwJYIm0HYuixock/9FEeqeUew== courcol@courcol.ch" >> /home/ubuntu/.ssh/authorized_keys
# Mike       
sudo echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCRTRSpJMLRRk0GuIcQ/OU5fGwgX0YhIMsy/sSgdzQc gevaert@theend" >> /home/ubuntu/.ssh/authorized_keys
# Daniel
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnwCEkde+9uNQJ+sUPJwuCGbCQM1NFa5T0uPZNbQFTe1cw3XhW8X+HZg9em5xdX6NrT+R3gHTMvpqhLepmZzcWNpautY7qGG833i/gKO2VrTWf/Vd0aRefvc9ssWChWKWxnJu0IGnOJF7gSA27MMWvFHjIoYzPG0UVmfE+Nr1OYLMjpYEsxqj+bby44xD7ii7/hVJXp1reuRjOiSK+AosO1GNIkXcw7CQJy1gQ9VAc3qpKwv5uqBTlvKG8olL42U0Ndy61slyQrbJm3GVFIQFd4aIpYjEGlY+B1jhY+wvf8RxxjCqpJ8bz+yG+/QPzGEZeaDNYsOTxWIJRVSm9voLf danielfr@aur" >> /home/ubuntu/.ssh/authorized_keys
# Erik
sudo echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCwlGHR/vz8esSOTMtXT0qnO7zg+kjPJYicxjyryO3h heeren@bbd-fsczyl3" >> /home/ubuntu/.ssh/authorized_keys

sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys


wget -O - https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc | gpg --dearmor | sudo tee /usr/share/keyrings/fsx-ubuntu-public-key.gpg > /dev/null
sudo bash -c 'echo "deb [signed-by=/usr/share/keyrings/fsx-ubuntu-public-key.gpg] https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/fsxlustreclientrepo.list && apt-get update'
sudo apt-get update
sudo apt-get install -y lustre-client-utils lustre-iokit lustre-tests
sudo apt-get install -y linux-aws lustre-client-modules-aws

sudo modprobe lustre
sudo mkdir /mnt/lustre

sudo mount -t lustre fs-05be5d491103b79ba.fsx.us-east-1.amazonaws.com@tcp:/b3myxamv /mnt/lustre
