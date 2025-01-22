locals {
  openscience_database_id = "nexus-openscience-db"
}

module "postgres_cluster_openscience" {
  source = "./postgres_cluster"
  count  = var.is_production ? 1 : 0

  providers = {
    aws = aws.nexus_openscience_postgres_tags
  }

  cluster_identifier              = local.openscience_database_id
  subnets_ids                     = module.networking.psql_subnets_ids
  security_group_id               = module.networking.main_subnet_sg_id
  instance_class                  = "db.m5d.large"
  nexus_postgresql_engine_version = "16"
  nexus_secrets_arn               = var.nexus_secrets_arn
}

# Blazegraph instance dedicated to Blazegraph views
module "blazegraph_openscience_bg" {
  source = "./blazegraph"
  count  = var.is_production ? 1 : 0

  providers = {
    aws = aws.nexus_openscience_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 16384
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms10g -Xmx10g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-openscience-bg"
  blazegraph_efs_name      = "blazegraph-openscience-bg"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus_openscience.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus_openscience.arn
}

# Blazegraph instance dedicated to composite views
module "blazegraph_openscience_composite" {
  source = "./blazegraph"
  count  = var.is_production ? 1 : 0

  providers = {
    aws = aws.nexus_openscience_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 16384
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms10g -Xmx10g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-openscience-composite"
  blazegraph_efs_name      = "blazegraph-openscience-composite"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus_openscience.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus_openscience.arn
}

module "elasticsearch_openscience" {
  source = "./elasticcloud"
  count  = var.is_production ? 1 : 0

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.16.1"

  hot_node_size  = "4g"
  hot_node_count = 2

  deployment_name = "nexus-openscience-elasticsearch"

  aws_tags = {
    Nexus       = "elastic",
    SBO_Billing = "nexus-openscience"
  }
}

module "nexus_delta_openscience" {
  source = "./delta"
  count  = var.is_production ? 1 : 0

  providers = {
    aws = aws.nexus_openscience_delta_tags
  }

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  domain_name = var.domain_name

  delta_cpu       = 4096
  delta_memory    = 10240
  delta_java_opts = "-Xss2m -Xms6g -Xmx6g"

  delta_instance_name        = "nexus-delta-openscience"
  delta_docker_image_version = "1.11.0-M8"
  delta_efs_name             = "delta-openscience"
  s3_bucket_arn              = aws_s3_bucket.nexus_openscience.arn
  s3_bucket_name             = var.nexus_openscience_bucket_name

  ecs_cluster_arn                          = aws_ecs_cluster.nexus_openscience.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus_openscience.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  private_delta_target_group_arn = module.openscience_delta_target_group.private_lb_target_group_arn
  dockerhub_credentials_arn      = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres_cluster_openscience[0].writer_endpoint
  postgres_reader_host = module.postgres_cluster_openscience[0].reader_endpoint

  elasticsearch_endpoint = module.elasticsearch_openscience[0].http_endpoint
  elastic_password_arn   = module.elasticsearch_openscience[0].elastic_user_credentials_secret_arn

  blazegraph_endpoint           = module.blazegraph_openscience_bg[0].http_endpoint
  blazegraph_composite_endpoint = module.blazegraph_openscience_composite[0].http_endpoint

  delta_search_config_commit = "b44315f7e078e4d0ae34d6bd3a596197e5a2b325"
  delta_config_file          = "delta-openscience.conf"
}

module "nexus_fusion_openscience" {
  source = "./fusion"
  count  = var.is_production ? 1 : 0

  providers = {
    aws = aws.nexus_openscience_fusion_tags
  }

  fusion_instance_name = "nexus-fusion-openscience"

  nexus_fusion_hostname  = "openbrainplatform.org"
  nexus_fusion_base_path = "/web/openscience/fusion/"
  nexus_delta_endpoint   = "https://openbrainplatform.org/api/openscience/nexus/v1"
  nexus_fusion_client_id = "nexus-openscience"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus_openscience.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus_openscience.arn

  private_aws_lb_target_group_nexus_fusion_arn = module.openscience_fusion_target_group.private_lb_target_group_arn
  dockerhub_credentials_arn                    = module.iam.dockerhub_credentials_arn
}
