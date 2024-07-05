module "postgres" {
  source = "./postgres"

  subnets_ids              = module.networking.psql_subnets_ids
  subnet_security_group_id = module.networking.main_subnet_sg_id
  instance_class           = "db.t4g.large"
}

module "elasticcloud" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.12.1"

  hot_node_size   = "4g"
  deployment_name = "nexus-es"
}

module "blazegraph" {
  source = "./blazegraph"

  blazegraph_cpu       = 1024
  blazegraph_memory    = 6144
  blazegraph_java_opts = "-Djava.awt.headless=true -Djava.awt.headless=true -XX:MaxDirectMemorySize=600m -Xms3g -Xmx3g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph"
  blazegraph_efs_name      = "sbo-poc-blazegraph"
  # needs to be like this for this instance; once it is decomissioned it doesn't have to be specified anymore

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "delta" {
  source = "./delta"

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  delta_cpu       = 4096
  delta_memory    = 8192
  delta_java_opts = "-Xms4g -Xmx4g"

  delta_instance_name  = "delta"
  delta_efs_name       = "delta-legacy" # legacy name so that the efs doesn't get modified
  s3_bucket_arn        = aws_s3_bucket.nexus_delta.arn
  nexus_delta_hostname = module.nexus_delta_target_group.hostname

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  delta_target_group_arn    = module.nexus_delta_target_group.lb_target_group_arn
  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres.host
  postgres_reader_host = module.postgres.host

  elasticsearch_endpoint = module.elasticcloud.http_endpoint
  elastic_password_key   = "elasticsearch_password"

  blazegraph_endpoint           = module.blazegraph.http_endpoint
  blazegraph_composite_endpoint = module.blazegraph.http_endpoint
  delta_search_config_commit    = "80fb06db5f5334da668504c7c66f17ad8585b57b"
  delta_config_file             = "legacy.conf"
}

module "fusion" {
  source               = "./fusion"
  fusion_instance_name = "fusion"

  nexus_fusion_hostname = module.nexus_fusion_target_group.hostname
  nexus_delta_hostname  = module.nexus_delta_target_group.hostname

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = module.nexus_fusion_target_group.lb_target_group_arn
  dockerhub_credentials_arn            = module.iam.dockerhub_credentials_arn
}