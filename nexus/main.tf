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

module "delta_target_group" {
  source = "./delta_target_group"

  nexus_delta_hostname     = "sbo-nexus-delta.shapes-registry.org"
  target_group_prefix      = "nx-dlt"
  unique_listener_priority = 100

  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  public_load_balancer_dns_name = var.public_load_balancer_dns_name
  nat_gateway_id                = var.nat_gateway_id
  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
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
  nexus_delta_hostname = module.delta_target_group.hostname

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  delta_target_group_arn    = module.delta_target_group.lb_target_group_arn
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

module "fusion_target_group" {
  source = "./fusion_target_group"

  nexus_fusion_hostname    = "sbo-nexus-fusion.shapes-registry.org"
  target_group_prefix      = "nx-fus"
  unique_listener_priority = 300

  aws_region                    = var.aws_region
  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  public_load_balancer_dns_name = var.public_load_balancer_dns_name
  nat_gateway_id                = var.nat_gateway_id
  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
}

module "fusion" {
  source               = "./fusion"
  fusion_instance_name = "fusion"

  nexus_fusion_hostname = module.fusion_target_group.hostname
  nexus_delta_hostname  = module.delta_target_group.hostname

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = module.fusion_target_group.lb_target_group_arn
  dockerhub_credentials_arn            = module.iam.dockerhub_credentials_arn
}

module "ship" {
  source = "./ship"

  dockerhub_credentials_arn   = module.iam.dockerhub_credentials_arn
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn           = var.nexus_secrets_arn
  postgres_host               = "https://replace.this.postgres.host"
  target_bucket_arn           = module.delta.nexus_delta_bucket_arn
  second_target_bucket_arn    = aws_s3_bucket.nexus.arn
}

#######################
## SECOND DEPLOYMENT ##
#######################

module "postgres_cluster" {
  source = "./postgres_cluster"

  subnets_ids       = module.networking.psql_subnets_ids
  security_group_id = module.networking.main_subnet_sg_id
  instance_class    = "db.m5d.large"
}

module "blazegraph_main" {
  source = "./blazegraph"

  blazegraph_cpu       = 3071
  blazegraph_memory    = 6144
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

  blazegraph_cpu       = 3071
  blazegraph_memory    = 6144
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

module "nexus_delta_target_group" {
  source = "./delta_target_group"

  nexus_delta_hostname     = "nexus-delta.shapes-registry.org"
  target_group_prefix      = "nxsdlt"
  unique_listener_priority = 101

  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  public_load_balancer_dns_name = var.public_load_balancer_dns_name
  nat_gateway_id                = var.nat_gateway_id
  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
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
  nexus_delta_hostname = module.nexus_delta_target_group.hostname

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  delta_target_group_arn    = module.nexus_delta_target_group.lb_target_group_arn
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

module "nexus_fusion_target_group" {
  source = "./fusion_target_group"

  nexus_fusion_hostname    = "nexus-fusion.shapes-registry.org"
  target_group_prefix      = "nxsfus"
  unique_listener_priority = 301

  aws_region                    = var.aws_region
  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  nat_gateway_id                = var.nat_gateway_id
  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  public_load_balancer_dns_name = var.public_load_balancer_dns_name
}

module "nexus_fusion" {
  source               = "./fusion"
  fusion_instance_name = "nexus_fusion"

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

moved {
  from = aws_iam_role.nexus_ecs_task_execution
  to   = module.iam.aws_iam_role.nexus_ecs_task_execution
}

moved {
  from = aws_iam_policy.cloudwatch_write_policy
  to   = module.iam.aws_iam_policy.cloudwatch_write_policy
}

moved {
  from = aws_iam_role_policy_attachment.ecs_task_execution_service
  to   = module.iam.aws_iam_role_policy_attachment.ecs_task_execution_service
}

moved {
  from = aws_iam_role_policy_attachment.nexus_secret_access
  to   = module.iam.aws_iam_role_policy_attachment.nexus_secret_access
}

moved {
  from = aws_iam_role_policy_attachment.cloudwatch_write_logs
  to   = module.iam.aws_iam_role_policy_attachment.cloudwatch_write_logs
}

moved {
  from = aws_iam_policy.nexus_secrets_access
  to   = module.iam.aws_iam_policy.nexus_secrets_access
}