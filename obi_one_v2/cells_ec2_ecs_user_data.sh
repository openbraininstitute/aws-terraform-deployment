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

#TODO: remove this key; currently for debugging
append_file_once 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCRTRSpJMLRRk0GuIcQ/OU5fGwgX0YhIMsy/sSgdzQc gevaert@bbd-jp8lt73' /home/ec2-user/.ssh/authorized_keys

install_s3_mount() {
    echo "install_s3_mount"
    yum install -y wget || return 1
    wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm || return 1
    yum install -y ./mount-s3.rpm || return 1
    mkdir -p /sbo/data/project || return 1
}
retry install_s3_mount

# https://github.com/awslabs/mountpoint-s3/issues/441#issuecomment-1676918612
echo "setup systemd service"
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
ExecStart=/bin/mount-s3 --read-only --allow-other ${cell_svc_perf_bucket_name} /sbo/data/project
ExecStop=/usr/bin/fusermount -u /sbo/data/project

[Install]
WantedBy=default.target
EOF

echo "systemctl enable mountpoint-s3.service"
systemctl enable mountpoint-s3.service
# to make sure all the services come up cleanly, we do a reboot
# if we try a `systemctl start mountpoint-s3.service`, then we get
# a lock since its dependencies aren't fulfilled since cloud-init hasn't finished
/usr/sbin/reboot
