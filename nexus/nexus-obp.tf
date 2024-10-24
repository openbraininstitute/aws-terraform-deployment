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
  instance_class                  = "db.m5d.xlarge"
  nexus_postgresql_engine_version = "16"

  aws_region = var.aws_region
}

# Blazegraph instance dedicated to Blazegraph views
module "blazegraph_obp_bg_4" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 10240
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms6g -Xmx6g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-bg-4"
  blazegraph_efs_name      = "blazegraph-obp-bg-4"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_region = var.aws_region
}

# Blazegraph instance dedicated to composite views
module "blazegraph_obp_composite_4" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 10240
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms6g -Xmx6g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-composite-4"
  blazegraph_efs_name      = "blazegraph-obp-composite-4"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_region = var.aws_region
}

module "elasticsearch_obp_2" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.15.2"

  hot_node_size  = "4g"
  hot_node_count = 2

  deployment_name = "nexus-obp-elasticsearch-2"

  aws_tags = {
    Nexus       = "elastic",
    SBO_Billing = "nexus"
  }
}

module "nexus_delta_obp_2" {
  source = "./delta"

  providers = {
    aws = aws.nexus_delta_tags
  }

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  delta_cpu       = 4096
  delta_memory    = 10240
  delta_java_opts = "-Xss2m -Xms6g -Xmx6g"

  delta_instance_name        = "nexus-delta-obp-2"
  delta_docker_image_version = "1.11.0-M1"
  delta_efs_name             = "delta-obp-2"
  s3_bucket_arn              = aws_s3_bucket.nexus_obp.arn
  s3_bucket_name             = var.nexus_obp_bucket_name

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  delta_target_group_arn         = module.obp_delta_target_group.lb_target_group_arn
  private_delta_target_group_arn = module.obp_delta_target_group.private_lb_target_group_arn
  dockerhub_credentials_arn      = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres_cluster_obp.writer_endpoint
  postgres_reader_host = module.postgres_cluster_obp.reader_endpoint

  elasticsearch_endpoint = module.elasticsearch_obp_2.http_endpoint
  elastic_password_arn   = module.elasticsearch_obp_2.elastic_user_credentials_secret_arn

  blazegraph_endpoint           = module.blazegraph_obp_bg_4.http_endpoint
  blazegraph_composite_endpoint = module.blazegraph_obp_composite_4.http_endpoint

  delta_search_config_commit = "2c042d052bb2a58fb77aaf01323b59c9ce132c96"
  delta_config_file          = "delta-obp-2.conf"

  aws_region = var.aws_region
}

module "nexus_fusion_obp" {
  source = "./fusion"
  providers = {
    aws = aws.nexus_fusion_tags
  }

  fusion_instance_name = "nexus-fusion-obp"

  nexus_fusion_hostname  = "openbluebrain.com"
  nexus_fusion_base_path = "/web/fusion/"
  nexus_delta_endpoint   = "https://openbluebrain.com/api/nexus/v1"


  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn         = module.obp_fusion_target_group.lb_target_group_arn
  private_aws_lb_target_group_nexus_fusion_arn = module.obp_fusion_target_group.private_lb_target_group_arn
  dockerhub_credentials_arn                    = module.iam.dockerhub_credentials_arn
}

module "dashboard" {
  source = "./dashboard"

  providers = {
    aws = aws.nexus_dashboard_tags
  }

  blazegraph_composite_service_name = module.blazegraph_obp_composite_4.service_name
  blazegraph_service_name           = module.blazegraph_obp_bg_4.service_name
  database                          = local.database_id
  delta_service_name                = module.nexus_delta_obp_2.service_name
  fusion_service_name               = module.nexus_fusion_obp.service_name
  s3_bucket                         = aws_s3_bucket.nexus_obp.bucket

  aws_region = var.aws_region
}
