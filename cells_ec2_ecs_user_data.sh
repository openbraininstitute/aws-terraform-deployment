#!/bin/bash

echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
yum install -y ./mount-s3.rpm

mount-s3 sbo-cell-svc-perf-test /sbo/data/project
EOF
