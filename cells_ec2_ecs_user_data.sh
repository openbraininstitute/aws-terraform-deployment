#!/bin/bash

echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

#TODO: remove this key; currently for debugging
echo -e "\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCRTRSpJMLRRk0GuIcQ/OU5fGwgX0YhIMsy/sSgdzQc gevaert@bbd-jp8lt73\n" >> /home/ec2-user/.ssh/authorized_keys

wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
yum install -y ./mount-s3.rpm

mount-s3 sbo-cell-svc-perf-test /sbo/data/project
EOF
