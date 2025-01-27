locals {
  database_id = "nexus-obp-db"
}

module "postgres_cluster_obp" {
  source = "./postgres_cluster"

  providers = {
    aws = aws.nexus_postgres_tags
  }

  cluster_identifier              = local.database_id
  subnets_ids                     = module.networking.psql_subnets_ids
  security_group_id               = module.networking.main_subnet_sg_id
  instance_class                  = "db.m5d.large"
  nexus_postgresql_engine_version = "16"
  nexus_secrets_arn               = var.nexus_secrets_arn
}

# Blazegraph instance dedicated to Blazegraph views
module "blazegraph_obp_bg" {
  source = "./blazegraph"
  count  = var.is_nexus_obp_running ? 1 : 0

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 16384
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms10g -Xmx10g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-bg"
  blazegraph_efs_name      = "blazegraph-obp-bg"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

# Blazegraph instance dedicated to composite views
module "blazegraph_obp_composite" {
  source = "./blazegraph"
  count  = var.is_nexus_obp_running ? 1 : 0

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 16384
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms10g -Xmx10g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-composite"
  blazegraph_efs_name      = "blazegraph-obp-composite"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "elasticsearch_obp" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.16.1"

  hot_node_size  = "4g"
  hot_node_count = 2

  deployment_name = "nexus-obp-elasticsearch"

  aws_tags = {
    Nexus       = "elastic",
    SBO_Billing = "nexus"
  }
}

module "nexus_delta_obp" {
  source = "./delta"
  count  = var.is_nexus_obp_running ? 1 : 0

  providers = {
    aws = aws.nexus_delta_tags
  }

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  domain_name = var.domain_name

  delta_cpu       = 4096
  delta_memory    = 10240
  delta_java_opts = "-Xss2m -Xms6g -Xmx6g"

  delta_instance_name        = "nexus-delta-obp"
  delta_docker_image_version = "1.11.0-M8"
  delta_efs_name             = "delta-obp"
  s3_bucket_arn              = aws_s3_bucket.nexus_obp.arn
  s3_bucket_name             = var.nexus_obp_bucket_name

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  private_delta_target_group_arn = module.obp_delta_target_group.private_lb_target_group_arn
  dockerhub_credentials_arn      = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres_cluster_obp.writer_endpoint
  postgres_reader_host = module.postgres_cluster_obp.reader_endpoint

  elasticsearch_endpoint = module.elasticsearch_obp.http_endpoint
  elastic_password_arn   = module.elasticsearch_obp.elastic_user_credentials_secret_arn

  blazegraph_endpoint           = module.blazegraph_obp_bg[0].http_endpoint
  blazegraph_composite_endpoint = module.blazegraph_obp_composite[0].http_endpoint

  delta_search_config_commit = "566e436e3cbd9b62fa8b710e3a52effcbf106b8f"
  delta_config_file          = "delta-obp.conf"
}


module "nexus_fusion_obp" {
  source = "./fusion"
  count  = var.is_nexus_obp_running ? 1 : 0
  providers = {
    aws = aws.nexus_fusion_tags
  }

  fusion_instance_name = "nexus-fusion-obp"

  nexus_fusion_hostname  = var.domain_name
  nexus_fusion_base_path = "/web/fusion/"
  nexus_delta_endpoint   = "https://${var.domain_name}/api/nexus/v1"
  nexus_fusion_client_id = "nexus-delta"


  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  private_aws_lb_target_group_nexus_fusion_arn = module.obp_fusion_target_group.private_lb_target_group_arn
  dockerhub_credentials_arn                    = module.iam.dockerhub_credentials_arn
}

module "dashboard" {
  source = "./dashboard"

  providers = {
    aws = aws.nexus_dashboard_tags
  }

  dashboard_name = "Nexus-OBP"

  blazegraph_composite_service_name = module.blazegraph_obp_composite[0].service_name
  blazegraph_composite_log_group    = module.blazegraph_obp_composite[0].log_group
  blazegraph_service_name           = module.blazegraph_obp_bg[0].service_name
  database                          = local.database_id
  delta_service_name                = module.nexus_delta_obp[0].service_name
  fusion_service_name               = module.nexus_fusion_obp[0].service_name
  s3_bucket                         = aws_s3_bucket.nexus_obp.bucket

  aws_region = var.aws_region
  account_id = var.account_id
}
