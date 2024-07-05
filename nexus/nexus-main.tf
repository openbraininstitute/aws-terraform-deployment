module "networking" {
  source = "./networking"

  aws_region     = var.aws_region
  nat_gateway_id = var.nat_gateway_id
  vpc_id         = var.vpc_id
}

module "iam" {
  source = "./iam"

  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  nexus_secrets_arn  = var.nexus_secrets_arn
  dockerhub_password = var.dockerhub_password
}

module "postgres_cluster" {
  source = "./postgres_cluster"

  subnets_ids       = module.networking.psql_subnets_ids
  security_group_id = module.networking.main_subnet_sg_id
  instance_class    = "db.m5d.large"
}

module "blazegraph_main" {
  source = "./blazegraph"

  blazegraph_cpu       = 4096
  blazegraph_memory    = 8192
  blazegraph_java_opts = "-Djava.awt.headless=true -Djava.awt.headless=true -XX:MaxDirectMemorySize=600m -Xms3g -Xmx3g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-main"
  blazegraph_efs_name      = "blazegraph-main"
  efs_blazegraph_data_dir  = "/bg-data"

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "blazegraph_composite" {
  source = "./blazegraph"

  blazegraph_cpu       = 4096
  blazegraph_memory    = 8192
  blazegraph_java_opts = "-Djava.awt.headless=true -Djava.awt.headless=true -XX:MaxDirectMemorySize=600m -Xms3g -Xmx3g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-composite"
  blazegraph_efs_name      = "blazegraph-composite"
  efs_blazegraph_data_dir  = "/bg-data"

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "elasticsearch" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.14.1"

  hot_node_size  = "4g"
  hot_node_count = 2

  deployment_name = "nexus-elasticsearch"
}

module "nexus_delta" {
  source = "./delta"

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  delta_cpu       = 4096
  delta_memory    = 8192
  delta_java_opts = "-Xms4g -Xmx4g"

  delta_instance_name  = "nexus-delta"
  delta_efs_name       = "delta"
  s3_bucket_arn        = aws_s3_bucket.nexus.arn
  nexus_delta_hostname = module.sbo_delta_target_group.hostname

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  delta_target_group_arn    = module.sbo_delta_target_group.lb_target_group_arn
  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres_cluster.writer_endpoint
  postgres_reader_host = module.postgres_cluster.reader_endpoint

  elasticsearch_endpoint = module.elasticsearch.http_endpoint
  elastic_password_key   = "elastic_password"

  blazegraph_endpoint           = module.blazegraph_main.http_endpoint
  blazegraph_composite_endpoint = module.blazegraph_composite.http_endpoint
  delta_search_config_commit    = "bd265a3d3cc4cd588fe93eda2ddaacd28ba32258"
  delta_config_file             = "delta.conf"
}

module "nexus_fusion" {
  source               = "./fusion"
  fusion_instance_name = "nexus_fusion"

  nexus_fusion_hostname = module.sbo_fusion_target_group.hostname
  nexus_delta_hostname  = module.sbo_delta_target_group.hostname

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = module.sbo_fusion_target_group.lb_target_group_arn
  dockerhub_credentials_arn            = module.iam.dockerhub_credentials_arn
}