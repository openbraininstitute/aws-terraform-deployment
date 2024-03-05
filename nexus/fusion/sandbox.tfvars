aws_region                               = "us-east-1"
subnet_id                                = "subnet-0b7efbe81901493e7"
subnet_security_group_id                 = "sg-07cb47bad77fe7b72"
ecs_cluster_arn                          = "arn:aws:ecs:us-east-1:058264116529:cluster/nexus_ecs_cluster"
aws_service_discovery_http_namespace_arn = "arn:aws:servicediscovery:us-east-1:058264116529:namespace/ns-3r4bdiyjxam2iad4"
nexus_delta_hostname                     = "delta-svc:8080"
nexus_fusion_hostname                    = "fusion-svc:8000"

# Come from outside nexus module
aws_lb_target_group_nexus_fusion_arn = ""
dockerhub_access_iam_policy_arn      = ""
