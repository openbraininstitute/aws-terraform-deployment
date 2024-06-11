module "networking" {
  source = "./networking"

  aws_region     = var.aws_region
  nat_gateway_id = var.nat_gateway_id
  vpc_id         = var.vpc_id
}

module "postgres" {
  source = "./postgres"

  subnets_ids                 = module.networking.psql_subnets_ids
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  instance_class              = "db.t4g.large"
  read_replica_instance_class = "db.t4g.medium"
}

module "elasticcloud" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  hot_node_size   = "4g"
  deployment_name = "nexus-es"
}

module "blazegraph" {
  source = "./blazegraph"

  blazegraph_cpu    = 1024
  blazegraph_memory = 6144

  blazegraph_instance_name = "blazegraph"
  blazegraph_efs_name      = "sbo-poc-blazegraph"
  # needs to be like this for this instance; once it is decomissioned it doesn't have to be specified anymore

  aws_region                  = var.aws_region
  vpc_id                      = var.vpc_id
  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = aws_iam_role.nexus_ecs_task_execution.arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "delta" {
  source = "./delta"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  delta_instance_name = "delta"
  delta_efs_name      = "sbo-poc-nexus-app-config" # legacy name so that the efs doesn't get modified
  s3_bucket_arn       = aws_s3_bucket.nexus_delta.arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = aws_iam_role.nexus_ecs_task_execution.arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  aws_lb_target_group_nexus_app_arn = aws_lb_target_group.nexus_app.arn
  dockerhub_credentials_arn         = var.dockerhub_credentials_arn

  postgres_host              = module.postgres.host
  postgres_host_read_replica = module.postgres.host_read_replica
  elasticsearch_endpoint     = module.elasticcloud.http_endpoint
  blazegraph_endpoint        = module.blazegraph.http_endpoint
}

module "fusion" {
  source = "./fusion"

  nexus_fusion_hostname = var.nexus_fusion_hostname
  nexus_delta_hostname  = var.nexus_delta_hostname

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = aws_iam_role.nexus_ecs_task_execution.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = aws_lb_target_group.nexus_fusion.arn
  dockerhub_credentials_arn            = var.dockerhub_credentials_arn
}

module "ship" {
  source = "./ship"

  dockerhub_credentials_arn   = var.dockerhub_credentials_arn
  ecs_task_execution_role_arn = aws_iam_role.nexus_ecs_task_execution.arn
  nexus_secrets_arn           = var.nexus_secrets_arn
  postgres_host               = module.postgres.second_host
  target_bucket_arn           = module.delta.nexus_delta_bucket_arn
  second_target_bucket_arn    = aws_s3_bucket.nexus.arn
}

#######################
## SECOND DEPLOYMENT ##
#######################

module "blazegraph_main" {
  source = "./blazegraph"

  blazegraph_cpu    = 256
  blazegraph_memory = 2048

  blazegraph_instance_name = "blazegraph-main"
  blazegraph_efs_name      = "blazegraph-main"
  efs_blazegraph_data_dir  = "/"

  aws_region                  = var.aws_region
  vpc_id                      = var.vpc_id
  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = aws_iam_role.nexus_ecs_task_execution.arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "elasticsearch" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  hot_node_size   = "1g"
  deployment_name = "nexus-elasticsearch"
}

moved {
  from = module.delta.aws_s3_bucket.nexus_delta
  to   = aws_s3_bucket.nexus_delta
}

moved {
  from = module.delta.aws_s3_bucket_public_access_block.nexus_delta
  to   = aws_s3_bucket_public_access_block.nexus_delta
}

moved {
  from = module.delta.aws_s3_bucket_metric.snexus_delta_metrics
  to   = aws_s3_bucket_metric.nexus_delta_metrics
}

moved {
  from = module.delta.aws_s3_bucket.nexus
  to   = aws_s3_bucket.nexus
}

moved {
  from = module.delta.aws_s3_bucket_public_access_block.nexus
  to   = aws_s3_bucket_public_access_block.nexus
}

moved {
  from = module.delta.aws_s3_bucket_metric.nexus
  to   = aws_s3_bucket_metric.nexus
}