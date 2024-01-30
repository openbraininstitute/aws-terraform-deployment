#!/bin/bash

echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

#TODO: remove this key; currently for debugging
cat << EOF >> /home/ec2-user/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCRTRSpJMLRRk0GuIcQ/OU5fGwgX0YhIMsy/sSgdzQc gevaert@bbd-jp8lt73
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTQQu/jmTIhy7MjfoOlW6pqgjKpUa4r86UKlME7Tu0/l46xcmvnu64SvE99rLNUolNXdbv7PcnW/yzZpQery4ZCUtAzHLpPZQomu5v3AGa60JGXHRqtKu6ogv83VLgbsoEOPW50+WeBxJJYdrHq6kwc4AwFHlG1L8OsAj/b41HH530nAH7ytFcd8Z5JbUeXbvvT4Eouu+BUuSxvdq5Heq4G4OoYTLc9k+Eby4rjzTv1y5cn6nEmkX/fxhEs6ac+QIyyx1DyUD4LuSRvnpmUrSDcpVtHu61vJzTktVqbylU7J5GcBV5RDoAoOm/WnS3thNbWa3Y//x57OVgUCYd9JLM83zLbanaVPGwIoO77uWfmarKOnmLC7ycdr1B9ZPtZog0HyOh7qT7zXe4PCos3BVEUkQbOfXtXpU9pfJ8ce6LG6T+CUdkc8BHBlxVitsT2m+0kQr9LbilBJcw1sWyHMv5N984q9TQfz3IuX1sMtnVMEVe45TNT6M7goBJqdJsaatiunN7B19EVw1mtvQ58wOhHuA9GBIFWbQ5KJb1vK/JXsyjeE1CCa2oKoIAJOJgxwPnmvjGBnuIiP61b+fRo8UVfwXW+KdD1drgoC4y2D8NfdfvPip/atFnPKciWL9NK6Ur1CXNHilrDeKVTG4T2Pk1/iE0FdCTblmvoCO7No92VQ== Gianluca
EOF

yum install -y wget
wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
yum install -y ./mount-s3.rpm

mkdir -p /sbo/data/project

# https://github.com/awslabs/mountpoint-s3/issues/441#issuecomment-1676918612
cat << EOF > /etc/systemd/system/mountpoint-s3.service
[Unit]
Description=Amazon S3 mount
Wants=cloud-init.target
After=cloud-init.target
AssertPathIsDirectory=/sbo/data/project

[Service]
Type=forking
User=root
Group=root
ExecStart=/bin/mount-s3 sbo-cell-svc-perf-test /sbo/data/project
ExecStop=/usr/bin/fusermount -u /sbo/data/project

[Install]
WantedBy=default.target
EOF

systemctl enable mountpoint-s3.service
systemctl start mountpoint-s3.service
