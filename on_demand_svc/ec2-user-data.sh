#!/bin/bash
echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
echo ECS_CONTAINER_INSTANCE_TAGS={${ecs_cluster_tags}} >> /etc/ecs/ecs.config
