#!/bin/bash

retry() {
  local attempts=0
  until "$@" || [ $attempts -eq 5 ]; do
    ((attempts++))
    sleep 60
  done
}

append_file_once() {
    local entry="$1"
    local file="$2"

    [ -f "$file" ] || touch "$file"
    grep -qF "$entry" "$file" || echo "$entry" >> "$file"
}
append_file_once 'ECS_CLUSTER=${ecs_cluster_name}' /etc/ecs/ecs.config
append_file_once 'ECS_CONTAINER_INSTANCE_TAGS={${ecs_cluster_tags}}' /etc/ecs/ecs.config

# TODO: remove this key; currently for debugging
append_file_once 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTQQu/jmTIhy7MjfoOlW6pqgjKpUa4r86UKlME7Tu0/l46xcmvnu64SvE99rLNUolNXdbv7PcnW/yzZpQery4ZCUtAzHLpPZQomu5v3AGa60JGXHRqtKu6ogv83VLgbsoEOPW50+WeBxJJYdrHq6kwc4AwFHlG1L8OsAj/b41HH530nAH7ytFcd8Z5JbUeXbvvT4Eouu+BUuSxvdq5Heq4G4OoYTLc9k+Eby4rjzTv1y5cn6nEmkX/fxhEs6ac+QIyyx1DyUD4LuSRvnpmUrSDcpVtHu61vJzTktVqbylU7J5GcBV5RDoAoOm/WnS3thNbWa3Y//x57OVgUCYd9JLM83zLbanaVPGwIoO77uWfmarKOnmLC7ycdr1B9ZPtZog0HyOh7qT7zXe4PCos3BVEUkQbOfXtXpU9pfJ8ce6LG6T+CUdkc8BHBlxVitsT2m+0kQr9LbilBJcw1sWyHMv5N984q9TQfz3IuX1sMtnVMEVe45TNT6M7goBJqdJsaatiunN7B19EVw1mtvQ58wOhHuA9GBIFWbQ5KJb1vK/JXsyjeE1CCa2oKoIAJOJgxwPnmvjGBnuIiP61b+fRo8UVfwXW+KdD1drgoC4y2D8NfdfvPip/atFnPKciWL9NK6Ur1CXNHilrDeKVTG4T2Pk1/iE0FdCTblmvoCO7No92VQ== gianluca.ficarelli@epfl.ch' /home/ec2-user/.ssh/authorized_keys

install_s3_mount() {
    echo "install_s3_mount"
    curl -LO https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm || return 1
    yum install -y ./mount-s3.rpm || return 1
    mkdir -p ${mounted_volume_host_path} || return 1
}
retry install_s3_mount

# https://github.com/awslabs/mountpoint-s3/issues/441#issuecomment-1676918612
echo "setup systemd service"
cat << EOF > /etc/systemd/system/mountpoint-s3.service
[Unit]
Description=Amazon S3 mount
Wants=cloud-init.target
After=cloud-init.target
AssertPathIsDirectory=${mounted_volume_host_path}

[Service]
Type=forking
User=root
Group=root
ExecStart=/bin/mount-s3 --read-only --allow-other ${shared_bucket_name} --region ${shared_bucket_region} --prefix ${shared_bucket_prefix} ${mounted_volume_host_path}
ExecStop=/usr/bin/fusermount -u ${mounted_volume_host_path}

[Install]
WantedBy=default.target
EOF

echo "systemctl enable mountpoint-s3.service"
systemctl enable mountpoint-s3.service
# to make sure all the services come up cleanly, we do a reboot
# if we try a `systemctl start mountpoint-s3.service`, then we get
# a lock since its dependencies aren't fulfilled since cloud-init hasn't finished
/usr/sbin/reboot
