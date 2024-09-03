module "nexus_sandbox_setup" {
  source = "./setup"
}

locals {
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  aws_region                    = "us-east-1"
  aws_account_id                = "058264116529"
  nat_gateway_id                = module.nexus_sandbox_setup.nat_gateway_id
  public_lb_listener_https_arn  = module.nexus_sandbox_setup.public_lb_listener_http_arn
  public_load_balancer_dns_name = module.nexus_sandbox_setup.public_load_balancer_dns_name
  vpc_id                        = module.nexus_sandbox_setup.vpc_id

  # All needed secrets from secret manager below
  nexus_secrets_arn           = "arn:aws:secretsmanager:us-east-1:058264116529:secret:nexus-25Vd68"
  psql_secret_arn             = "arn:aws:secretsmanager:us-east-1:058264116529:secret:nexus_postgresql_password-CPEAmn"
  ec_api_key_arn              = "arn:aws:secretsmanager:us-east-1:058264116529:secret:ec_api_key-ET0Y5u"
  nise_dockerhub_password_arn = "arn:aws:secretsmanager:us-east-1:058264116529:secret:nise_dockerhub_password-l7Bs4c"

  database_id = "nexus-db"
}

data "aws_secretsmanager_secret_version" "nise_dockerhub_password" {
  secret_id = local.nise_dockerhub_password_arn
}

####

resource "aws_ecs_cluster" "nexus" {
  name = "nexus_ecs_cluster"
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_service_discovery_http_namespace" "nexus" {
  name        = "nexus-sandbox"
  description = "nexus service discovery namespace"
}

resource "aws_s3_bucket" "nexus_delta" {
  bucket = "nexus-delta-sandbox"
}
resource "aws_s3_bucket_public_access_block" "nexus_delta" {
  bucket = aws_s3_bucket.nexus_delta.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

####

module "networking" {
  source = "../networking"

  aws_region     = local.aws_region
  nat_gateway_id = local.nat_gateway_id
  vpc_id         = local.vpc_id
}

module "iam" {
  source = "../iam"

  aws_account_id = local.aws_account_id
  aws_region     = local.aws_region

  nexus_secrets_arn  = local.nexus_secrets_arn
  dockerhub_password = data.aws_secretsmanager_secret_version.nise_dockerhub_password.secret_string

  secret_recovery_window_in_days = 0
}

module "postgres" {
  source = "../postgres"

  database_identifier      = local.database_id
  subnets_ids              = module.networking.psql_subnets_ids
  subnet_security_group_id = module.networking.main_subnet_sg_id
  instance_class           = "db.t4g.small"

  nexus_postgresql_database_password_arn = local.psql_secret_arn

  aws_region = local.aws_region
}

module "elasticcloud" {
  source = "../elasticcloud"

  aws_region               = local.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.14.3"

  hot_node_size   = "1g"
  deployment_name = "nexus-sandbox"

  secret_recovery_window_in_days = 0

  aws_tags = {
    Nexus = "elastic"
  }
}

module "blazegraph" {
  source = "../blazegraph"

  blazegraph_cpu    = 1024
  blazegraph_memory = 6144

  blazegraph_instance_name = "blazegraph-sandbox"
  blazegraph_efs_name      = "blazegraph-sandbox"
  blazegraph_java_opts     = ""

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_region = local.aws_region
}

module "delta_target_group" {
  source = "../path_target_group"

  target_port       = 8080
  base_path         = "/api/nexus"
  health_check_path = "/api/nexus/v1/version"

  allowed_source_ip_cidr_blocks = local.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = local.public_lb_listener_https_arn
  target_group_prefix           = "obpdlt"
  unique_listener_priority      = 101
  nat_gateway_id                = local.nat_gateway_id
  vpc_id                        = local.vpc_id
}

module "delta" {
  source = "../delta"

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  delta_cpu    = 1024
  delta_memory = 2048

  delta_instance_name        = "delta-sandbox"
  delta_docker_image_version = "latest"
  delta_efs_name             = "delta-sandbox" # legacy name so that the efs doesn't get modified
  s3_bucket_arn              = aws_s3_bucket.nexus_delta.arn
  delta_java_opts            = ""

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = local.nexus_secrets_arn

  delta_target_group_arn    = module.delta_target_group.lb_target_group_arn
  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres.host
  postgres_reader_host = module.postgres.host

  elasticsearch_endpoint = module.elasticcloud.http_endpoint
  elastic_password_arn   = module.elasticcloud.elastic_user_credentials_secret_arn

  blazegraph_endpoint           = module.blazegraph.http_endpoint
  blazegraph_composite_endpoint = module.blazegraph.http_endpoint
  delta_search_config_commit    = "80fb06db5f5334da668504c7c66f17ad8585b57b"
  delta_config_file             = "delta-sandbox.conf"

  aws_region = local.aws_region
}

module "fusion_target_group" {
  source = "../path_target_group"

  target_port       = 8000
  base_path         = "/web/fusion"
  health_check_path = "/web/fusion/status"

  allowed_source_ip_cidr_blocks = local.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = local.public_lb_listener_https_arn
  target_group_prefix           = "obpfus"
  unique_listener_priority      = 301
  nat_gateway_id                = local.nat_gateway_id
  vpc_id                        = local.vpc_id
}

module "fusion" {
  source               = "../fusion"
  fusion_instance_name = "fusion"

  nexus_fusion_hostname = "openbluebrain.sandbox"

  aws_region               = local.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = module.fusion_target_group.lb_target_group_arn
  dockerhub_credentials_arn            = module.iam.dockerhub_credentials_arn

  nexus_delta_endpoint   = "https://openbluebrain.sandbox/api/nexus/v1"
  nexus_fusion_base_path = "/nexus/web/"
}

module "dashboard" {
  source                            = "../dashboard"
  blazegraph_composite_service_name = module.blazegraph.service_name
  blazegraph_service_name           = module.blazegraph.service_name
  database                          = local.database_id
  delta_service_name                = module.delta.service_name
  fusion_service_name               = module.fusion.service_name
  s3_bucket                         = aws_s3_bucket.nexus_delta.bucket

  aws_region = local.aws_region
}