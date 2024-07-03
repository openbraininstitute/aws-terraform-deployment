module "nexus_sandbox_setup" {
  source = "./setup"
}

locals {
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  aws_region                    = "us-east-1"
  aws_account_id                = "058264116529"
  domain_zone_id                = module.nexus_sandbox_setup.domain_zone_id
  nat_gateway_id                = module.nexus_sandbox_setup.nat_gateway_id
  public_lb_listener_https_arn  = module.nexus_sandbox_setup.public_lb_listener_http_arn
  public_load_balancer_dns_name = module.nexus_sandbox_setup.public_load_balancer_dns_name
  vpc_id                        = module.nexus_sandbox_setup.vpc_id

  nexus_secrets_arn = "arn:aws:secretsmanager:us-east-1:058264116529:secret:nexus-HoRddo"
  psql_secret_arn   = "arn:aws:secretsmanager:us-east-1:058264116529:secret:nexus_postgresql_password-bX9Jo7"
}

# Define this as TF_VAR_nise_dockerhub_password env variable. Currently
# this password can be found in the NISE 1password.
variable "nise_dockerhub_password" {
  type      = string
  sensitive = true
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
  dockerhub_password = var.nise_dockerhub_password
}

module "postgres" {
  source = "../postgres"

  subnets_ids              = module.networking.psql_subnets_ids
  subnet_security_group_id = module.networking.main_subnet_sg_id
  instance_class           = "db.t4g.small"

  nexus_postgresql_database_password_arn = local.psql_secret_arn
}

module "elasticcloud" {
  source = "../elasticcloud"

  aws_region               = local.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.12.1"

  hot_node_size   = "1g"
  deployment_name = "nexus-sandbox-es"
}

module "blazegraph" {
  source = "../blazegraph"

  blazegraph_cpu    = 1024
  blazegraph_memory = 6144

  blazegraph_instance_name = "blazegraph-sandbox"
  blazegraph_efs_name      = "blazegraph-sandbox"

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "delta_target_group" {
  source = "../delta_target_group"

  nexus_delta_hostname     = "sbo-nexus-delta.shapes-registry.org"
  target_group_prefix      = "nx-dlt"
  unique_listener_priority = 100

  vpc_id                        = local.vpc_id
  domain_zone_id                = local.domain_zone_id
  public_lb_listener_https_arn  = local.public_lb_listener_https_arn
  public_load_balancer_dns_name = local.public_load_balancer_dns_name
  nat_gateway_id                = local.nat_gateway_id
  allowed_source_ip_cidr_blocks = local.allowed_source_ip_cidr_blocks
}

module "delta" {
  source = "../delta"

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  delta_cpu    = 1024
  delta_memory = 2048

  delta_instance_name  = "delta-sandbox"
  delta_efs_name       = "delta-sandbox" # legacy name so that the efs doesn't get modified
  s3_bucket_arn        = aws_s3_bucket.nexus_delta.arn
  nexus_delta_hostname = module.delta_target_group.hostname

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = local.nexus_secrets_arn

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
  source = "../fusion_target_group"

  nexus_fusion_hostname    = "sbo-nexus-fusion.shapes-registry.org"
  target_group_prefix      = "nx-fus"
  unique_listener_priority = 300

  aws_region                    = local.aws_region
  vpc_id                        = local.vpc_id
  domain_zone_id                = local.domain_zone_id
  public_lb_listener_https_arn  = local.public_lb_listener_https_arn
  public_load_balancer_dns_name = local.public_load_balancer_dns_name
  nat_gateway_id                = local.nat_gateway_id
  allowed_source_ip_cidr_blocks = local.allowed_source_ip_cidr_blocks
}

module "fusion" {
  source               = "../fusion"
  fusion_instance_name = "fusion"

  nexus_fusion_hostname = module.fusion_target_group.hostname
  nexus_delta_hostname  = module.delta_target_group.hostname

  aws_region               = local.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = module.fusion_target_group.lb_target_group_arn
  dockerhub_credentials_arn            = module.iam.dockerhub_credentials_arn

}