#!/bin/bash
set -eux

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
append_file_once '${efs_id}:/ /data/efs efs _netdev,tls 0 0' /etc/fstab

# TODO: remove this key; currently for debugging
append_file_once 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTQQu/jmTIhy7MjfoOlW6pqgjKpUa4r86UKlME7Tu0/l46xcmvnu64SvE99rLNUolNXdbv7PcnW/yzZpQery4ZCUtAzHLpPZQomu5v3AGa60JGXHRqtKu6ogv83VLgbsoEOPW50+WeBxJJYdrHq6kwc4AwFHlG1L8OsAj/b41HH530nAH7ytFcd8Z5JbUeXbvvT4Eouu+BUuSxvdq5Heq4G4OoYTLc9k+Eby4rjzTv1y5cn6nEmkX/fxhEs6ac+QIyyx1DyUD4LuSRvnpmUrSDcpVtHu61vJzTktVqbylU7J5GcBV5RDoAoOm/WnS3thNbWa3Y//x57OVgUCYd9JLM83zLbanaVPGwIoO77uWfmarKOnmLC7ycdr1B9ZPtZog0HyOh7qT7zXe4PCos3BVEUkQbOfXtXpU9pfJ8ce6LG6T+CUdkc8BHBlxVitsT2m+0kQr9LbilBJcw1sWyHMv5N984q9TQfz3IuX1sMtnVMEVe45TNT6M7goBJqdJsaatiunN7B19EVw1mtvQ58wOhHuA9GBIFWbQ5KJb1vK/JXsyjeE1CCa2oKoIAJOJgxwPnmvjGBnuIiP61b+fRo8UVfwXW+KdD1drgoC4y2D8NfdfvPip/atFnPKciWL9NK6Ur1CXNHilrDeKVTG4T2Pk1/iE0FdCTblmvoCO7No92VQ== gianluca.ficarelli@epfl.ch' /home/ec2-user/.ssh/authorized_keys

# Create the directory for mounting efs after the reboot
mkdir -p /data/efs

install_s3_mount() {
    echo "install_s3_mount"
    curl -LO https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm || return 1
    yum install -y ./mount-s3.rpm || return 1
}
retry install_s3_mount

# https://github.com/awslabs/mountpoint-s3/issues/441#issuecomment-1676918612
%{ for cfg in mount_buckets ~}
echo "Setup mountpoint and systemd service for ${cfg.volume_name}"

MOUNT_DIR="${mount_base_dir}${cfg.volume_host_path}"
SERVICE="mountpoint-s3-${cfg.volume_name}.service"
mkdir -p "$MOUNT_DIR"

cat << EOF > "/etc/systemd/system/$SERVICE"
[Unit]
Description=Amazon S3 mount [${cfg.volume_name}]
Wants=cloud-init.target
After=cloud-init.target
AssertPathIsDirectory=$MOUNT_DIR

[Service]
Type=forking
User=root
Group=root
ExecStart=/bin/mount-s3 \
  --read-only \
  --allow-other \
  --region "${cfg.bucket_region}" \
  --prefix "${cfg.bucket_prefix}" \
  ${cfg.mount_extra_options} \
  "${cfg.bucket_name}" \
  "$MOUNT_DIR"
ExecStop=/usr/bin/fusermount -u "$MOUNT_DIR"

[Install]
WantedBy=default.target
EOF

echo "systemctl enable $SERVICE"
systemctl enable "$SERVICE"

%{ endfor ~}

# to make sure all the services come up cleanly, we do a reboot
# if we try a `systemctl start mountpoint-s3.service`, then we get
# a lock since its dependencies aren't fulfilled since cloud-init hasn't finished
/usr/sbin/reboot
