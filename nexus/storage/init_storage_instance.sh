#!/bin/bash

# Enable EC2 instance to be picked up by ECS service
echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

# Mount S3 bucket
yum install -y wget
wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
yum install -y ./mount-s3.rpm

mkdir -p /sbo/data/project

mount-s3 ${s3_bucket_name} /sbo/data/project --allow-other --file-mode 0777 --dir-mode 0777 --allow-overwrite --allow-delete
