module "postgres_cluster_obp" {
  source = "./postgres_cluster"

  providers = {
    aws = aws.nexus_postgres_tags
  }

  cluster_identifier              = "nexus-obp-db"
  subnets_ids                     = module.networking.psql_subnets_ids
  security_group_id               = module.networking.main_subnet_sg_id
  instance_class                  = "db.m5d.large"
  nexus_postgresql_engine_version = "16"

  aws_region = var.aws_region
}

# Blazegraph instance dedicated to Blazegraph views
module "blazegraph_obp_bg_2" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 10240
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=40000000 -XX:MaxDirectMemorySize=600m -Xms5g -Xmx5g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-bg-2"
  blazegraph_efs_name      = "blazegraph-obp-bg-2"
  efs_blazegraph_data_dir  = "/bg-data"

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_region = var.aws_region
}

# Blazegraph instance dedicated to composite views
module "blazegraph_obp_composite_2" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 10240
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=40000000 -XX:MaxDirectMemorySize=600m -Xms5g -Xmx5g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-composite-2"
  blazegraph_efs_name      = "blazegraph-obp-composite-2"
  efs_blazegraph_data_dir  = "/bg-data"

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

  elasticsearch_version = "8.14.3"

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
  delta_memory    = 8192
  delta_java_opts = "-Xms4g -Xmx4g"

  delta_instance_name        = "nexus-delta-obp-2"
  delta_docker_image_version = "1.10.0-M17"
  delta_efs_name             = "delta-obp-2"
  s3_bucket_arn              = aws_s3_bucket.nexus_obp.arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  delta_target_group_arn    = module.obp_delta_target_group_2.lb_target_group_arn
  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres_cluster_obp.writer_endpoint
  postgres_reader_host = module.postgres_cluster_obp.reader_endpoint

  elasticsearch_endpoint = module.elasticsearch_obp_2.http_endpoint
  elastic_password_arn   = module.elasticsearch_obp_2.elastic_user_credentials_secret_arn

  blazegraph_endpoint           = module.blazegraph_obp_bg_2.http_endpoint
  blazegraph_composite_endpoint = module.blazegraph_obp_composite_2.http_endpoint

  delta_search_config_commit = "a8a05d1ee7aa0a2d89231c9f55f38f934dc24153"
  delta_config_file          = "delta-obp-2.conf"

  aws_region = var.aws_region
}
