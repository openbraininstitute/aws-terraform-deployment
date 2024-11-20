locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id

  private_alb_https_listener_arn = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  public_nlb_sg_id = data.terraform_remote_state.common.outputs.public_nlb_sg_id
  domain_zone_id   = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id   = data.terraform_remote_state.common.outputs.nat_gateway_id

  vpc_cidr_block    = data.terraform_remote_state.common.outputs.vpc_cidr_block
  vpc_default_sg_id = data.terraform_remote_state.common.outputs.vpc_default_sg_id

  primary_domain = data.terraform_remote_state.common.outputs.primary_domain

  virtual_lab_manager_secrets_arn = data.terraform_remote_state.common.outputs.virtual_lab_manager_secrets_arn
  keycloak_secrets_arn            = data.terraform_remote_state.common.outputs.keycloak_secrets_arn
  core_webapp_secrets_arn         = data.terraform_remote_state.common.outputs.core_webapp_secrets_arn
  ml_secrets_arn                  = data.terraform_remote_state.common.outputs.ml_secrets_arn
  bluenaas_service_secrets_arn    = data.terraform_remote_state.common.outputs.bluenaas_service_secrets_arn
  accounting_service_secrets_arn  = data.terraform_remote_state.common.outputs.accounting_service_secrets_arn
  hpc_slurm_secrets_arn           = data.terraform_remote_state.common.outputs.hpc_slurm_secrets_arn
}

module "dockerhub_secret" {
  source = "./dockerhub_secret"
}

module "coreservices_key" {
  source = "./ssh_key"

  # Stored at:
  # systems/services/external/aws/ssh/aws_coreservices_public_key
  # systems/services/external/aws/ssh/aws_coreservices_private_key
  # systems/services/external/aws/ssh/aws_coreservices_password
  name       = "aws_coreservices"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO8QAh2WZ/WcZnNeojPNhadeodMO2l3PssaUFJWfvEFNzkuo5ci7nxb39M2FH6RyFAfqykV/v89KfDIg9K2ebJQZS+x6Enrqm7+ROmZjCdpYkFm7l2NCoKLus92DaPX6k1Tv5hcI76BqWN4nOKQxzb7ziJxFl5wzLgTwnXZvY33dA3Pu6aimksv071KnQ3hJKk6Omx/l7Hv/D7c0tU8vRCUefzHT3TkRpRgTTq+Wd8S0pGSmMB4drk5PiUzEVczxuIfmYGCWV2va6aT34yuMOw/6y2Cr9guCkyR2FkFm7q0MPw0aKGFBwTT05eiEWBWKQQbqi1qMtSwd6tp4qv6crN SSH key for AWS SBO POC"
}

module "networking" {
  source = "./networking"

  vpc_id         = local.vpc_id
  aws_region     = local.aws_region
  vpc_cidr_block = local.vpc_cidr_block
  route_table_id = local.route_table_private_subnets_id
}

module "cs" {
  source = "./cs"

  vpc_id                         = local.vpc_id
  aws_region                     = local.aws_region
  route_table_private_subnets_id = local.route_table_private_subnets_id
  db_instance_class              = "db.t3.micro"
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  keycloak_secrets_arn           = local.keycloak_secrets_arn

  preferred_hostname = local.primary_domain
  redirect_hostnames = ["openbluebrain.ch", "openbrainplatform.org", "openbrainplatform.com"]

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  account_id                    = local.account_id
}

module "ml" {
  source = "./ml"

  aws_region = local.aws_region
  account_id = local.account_id

  is_production = var.is_production

  ml_secrets_arn = local.ml_secrets_arn

  vpc_id                         = local.vpc_id
  vpc_cidr_block                 = local.vpc_cidr_block
  route_table_private_subnets_id = local.route_table_private_subnets_id

  dockerhub_credentials_arn = module.dockerhub_secret.dockerhub_credentials_arn
  backend_image_tag         = "scholarag-v0.0.7"
  etl_image_tag             = "scholaretl-v0.0.6"
  agent_image_tag           = "neuroagent-v0.3.3"
  grobid_image_url          = "lfoppiano/grobid:0.8.0"

  paper_bucket_name = "ml-paper-bucket"


  # OLD PRIVATE ALB
  private_alb_security_group_id = data.terraform_remote_state.common.outputs.private_alb_security_group_id
  private_alb_listener_arn      = data.terraform_remote_state.common.outputs.private_alb_listener_3000_arn
  private_alb_dns               = data.terraform_remote_state.common.outputs.private_alb_dns_name

  # NEW PRIVATE ALB
  generic_private_alb_listener_arn      = local.private_alb_https_listener_arn
  generic_private_alb_security_group_id = data.terraform_remote_state.common.outputs.generic_private_alb_security_group_id

  github_repos                           = ["BlueBrain/neuroagent", "BlueBrain/scholarag", "BlueBrain/scholaretl"]
  epfl_cidr                              = var.epfl_cidr
  bbp_dmz_cidr                           = var.bbp_dmz_cidr
  readonly_access_policy_statement_part1 = local.readonly_access_policy_statement_part1
  readonly_access_policy_statement_part2 = local.readonly_access_policy_statement_part2
  aws_ssoadmin_instances_arns            = data.aws_ssoadmin_instances.ssoadmin_instances.arns
}

module "nexus" {
  source = "./nexus"

  aws_region         = local.aws_region
  account_id         = local.account_id
  vpc_id             = local.vpc_id
  domain_name        = local.primary_domain
  dockerhub_password = var.nise_dockerhub_password

  domain_zone_id = local.domain_zone_id
  nat_gateway_id = local.nat_gateway_id

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  nexus_obp_bucket_name         = "nexus-obp-production"
  nexus_openscience_bucket_name = "nexus-openscience-production"
  nexus_ship_bucket_name        = "nexus-ship-production"

  private_lb_listener_https_arn = local.private_alb_https_listener_arn

  readonly_access_policy_statement_part1 = local.readonly_access_policy_statement_part1
  readonly_access_policy_statement_part2 = local.readonly_access_policy_statement_part2
  aws_ssoadmin_instances_arns            = data.aws_ssoadmin_instances.ssoadmin_instances.arns
  is_production                          = var.is_production

}

module "viz" {
  source = "./viz"

  aws_region = local.aws_region
  account_id = local.account_id
  vpc_id     = local.vpc_id

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  secret_dockerhub_arn            = module.dockerhub_secret.dockerhub_credentials_arn

  scientific_data_bucket_name = "important-scientific-data"

  domain_zone_id           = local.domain_zone_id
  nat_gateway_id           = local.nat_gateway_id
  private_alb_listener_arn = local.private_alb_https_listener_arn

  aws_security_group_nlb_id      = local.public_nlb_sg_id
  route_table_private_subnets_id = local.route_table_private_subnets_id

  readonly_access_policy_statement_part1 = local.readonly_access_policy_statement_part1
  readonly_access_policy_statement_part2 = local.readonly_access_policy_statement_part2
  aws_ssoadmin_instances_arns            = data.aws_ssoadmin_instances.ssoadmin_instances.arns
  is_production                          = var.is_production

}

module "cells_svc" {
  source = "./cells_svc"

  aws_region = local.aws_region

  vpc_id         = local.vpc_id
  vpc_cidr_block = local.vpc_cidr_block

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_private_subnets_id = local.route_table_private_subnets_id

  cell_svc_perf_bucket_name = aws_s3_bucket.sbo-cell-svc-perf-test.id

  aws_coreservices_ssh_key_id = module.coreservices_key.key_pair_id

  root_path = "/api/circuit"

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id
}

module "nse" {
  source = "./nse"

  aws_region                = local.aws_region
  account_id                = local.account_id
  vpc_id                    = local.vpc_id
  dockerhub_credentials_arn = module.dockerhub_secret.dockerhub_credentials_arn
  amazon_linux_ecs_ami_id   = data.aws_ami.amazon_linux_2_ecs.id
  route_table_id            = local.route_table_private_subnets_id

  me_model_analysis_docker_image_url = "bluebrain/me-model-analysis:latest"
}

module "bluenaas_svc" {
  source = "./bluenaas_svc"

  aws_region                 = local.aws_region
  account_id                 = local.account_id
  vpc_id                     = local.vpc_id
  private_alb_listener_arn   = local.private_alb_https_listener_arn
  alb_listener_rule_priority = 750
  internet_access_route_id   = local.route_table_private_subnets_id

  bluenaas_service_secrets_arn = local.bluenaas_service_secrets_arn

  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn
  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn

  keycloak_server_url = "https://${local.primary_domain}/auth/"

  base_path = "/api/bluenaas"
}

module "hpc" {
  source = "./hpc"

  aws_region                 = local.aws_region
  account_id                 = local.account_id
  obp_vpc_id                 = local.vpc_id
  obp_vpc_default_sg_id      = local.vpc_default_sg_id
  sbo_billing                = "hpc"
  slurm_mysql_admin_username = "slurm_admin"
  create_compute_instances   = false
  num_compute_instances      = 0
  create_slurmdb             = false # TODO-SLURMDB: re-enable when redeploying the cluster
  compute_instance_type      = "m7g.medium"
  create_jumphost            = false
  compute_nat_access         = false
  compute_subnet_count       = 16
  av_zone_suffixes           = ["a"]
  peering_route_tables       = [local.route_table_private_subnets_id]
  lambda_subnet_cidr         = "10.0.16.0/24"
  is_production              = var.is_production
  aws_endpoints_subnet_cidr  = module.networking.endpoints_subnet_cidr
  endpoints_route_table_id   = local.route_table_private_subnets_id
  hpc_slurm_secrets_arn      = local.hpc_slurm_secrets_arn
}

module "static-server" {
  source = "./static-server"

  aws_region                 = local.aws_region
  account_id                 = local.account_id
  vpc_id                     = local.vpc_id
  public_subnet_ids          = [data.terraform_remote_state.common.outputs.public_a_subnet_id, data.terraform_remote_state.common.outputs.public_b_subnet_id]
  domain_name                = local.primary_domain
  static_content_bucket_name = local.primary_domain
  alb_listener_arn           = local.private_alb_https_listener_arn
  alb_listener_rule_priority = 600
}

module "core_webapp" {
  source = "./core_webapp"

  core_webapp_log_group_name           = "core_webapp"
  vpc_id                               = local.vpc_id
  core_webapp_ecs_number_of_containers = 1
  private_alb_https_listener_arn       = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  aws_region                           = local.aws_region
  account_id                           = local.account_id
  core_webapp_docker_image_url         = "bluebrain/sbo-core-web-app:latest"
  dockerhub_access_iam_policy_arn      = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn            = module.dockerhub_secret.dockerhub_credentials_arn
  core_webapp_base_path                = "/app"
  route_table_id                       = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks        = ["0.0.0.0/0"]
  vpc_cidr_block                       = local.vpc_cidr_block
  core_webapp_secrets_arn              = local.core_webapp_secrets_arn

  env_DEBUG                               = "true"
  env_NEXTAUTH_URL                        = "https://${local.primary_domain}/app/api/auth"
  env_KEYCLOAK_ISSUER                     = "https://${local.primary_domain}/auth/realms/SBO"
  env_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY  = "pk_test_51P6uAFFE4Bi50cLlatJIc0fUPsP0jQkaCCJ8TTkIYOOLIrLzxX1M9p1kVD11drNqsF9p7yiaumWJ8UHb3ptJJRXB00y3qjYReV"
  env_NEXT_PUBLIC_BBS_ML_PRIVATE_BASE_URL = "http://${data.terraform_remote_state.common.outputs.private_alb_dns_name}:3000/api/literature"
}

module "accounting_svc" {
  source = "./accounting_svc"

  aws_region                    = local.aws_region
  account_id                    = local.account_id
  vpc_id                        = local.vpc_id
  private_alb_listener_arn      = local.private_alb_https_listener_arn
  internet_access_route_id      = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks = [var.epfl_cidr, var.bbp_dmz_cidr, local.vpc_cidr_block, ]

  accounting_service_secrets_arn = local.accounting_service_secrets_arn

  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn
  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn

  root_path = "/api/accounting"
}

module "kg_inference_api" {
  source = "./kg-inference-api"

  # domain_zone_id                = local.domain_zone_id
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_id                 = local.route_table_private_subnets_id
  vpc_cidr_block                 = local.vpc_cidr_block
  vpc_id                         = local.vpc_id

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  aws_region                        = local.aws_region
  account_id                        = local.account_id
  allowed_source_ip_cidr_blocks     = ["0.0.0.0/0"]
  kg_inference_api_docker_image_url = "bluebrain/kg-inference-api:latest"
  kg_inference_api_base_path        = "/api/kg-inference"
  kg_inference_api_log_group_name   = "kg_inference_api"
}

module "thumbnail_generation_api" {
  source = "./thumbnail-generation-api"

  #domain_zone_id                = local.domain_zone_id
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_id                 = local.route_table_private_subnets_id
  vpc_cidr_block                 = local.vpc_cidr_block
  vpc_id                         = local.vpc_id

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  aws_region                                = local.aws_region
  account_id                                = local.account_id
  allowed_source_ip_cidr_blocks             = ["0.0.0.0/0"]
  thumbnail_generation_api_docker_image_url = "bluebrain/thumbnail-generation-api:latest"
  thumbnail_generation_api_base_path        = "/api/thumbnail-generation"
  thumbnail_generation_api_log_group_name   = "thumbnail_generation_api"
}

module "virtual_lab_manager" {
  source = "./virtual-lab-manager"

  vpc_id                         = local.vpc_id
  aws_region                     = local.aws_region
  account_id                     = local.account_id
  vpc_cidr_block                 = local.vpc_cidr_block
  nat_gateway_id                 = local.nat_gateway_id
  allowed_source_ip_cidr_blocks  = [local.vpc_cidr_block]
  private_lb_listener_https_arn  = local.private_alb_https_listener_arn
  route_table_private_subnets_id = local.route_table_private_subnets_id

  invite_link = "https://${local.primary_domain}/app"
  mail_from   = "noreply@${local.primary_domain}"

  virtual_lab_manager_postgres_db   = "vlm"
  virtual_lab_manager_postgres_user = "vlm_user"

  log_group_name = var.virtual_lab_manager_log_group_name

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  virtual_lab_manager_docker_image_url = var.virtual_lab_manager_docker_image_url

  keycloak_server_url = "https://${local.primary_domain}/auth/"

  virtual_lab_manager_secrets_arn = local.virtual_lab_manager_secrets_arn

  ecs_number_of_containers = var.virtual_lab_manager_ecs_number_of_containers

  virtual_lab_manager_depoloyment_env = "production"

  virtual_lab_manager_nexus_delta_uri = "https://${local.primary_domain}/api/nexus/v1"

  virtual_lab_manager_invite_expiration = "7"

  virtual_lab_manager_mail_username = "AKIAZYSNA64ZRY6UDRMA"
  virtual_lab_manager_mail_server   = "email-smtp.${local.aws_region}.amazonaws.com"
  virtual_lab_manager_base_path     = var.virtual_lab_manager_base_path

  virtual_lab_manager_mail_port = "25"

  virtual_lab_manager_mail_starttls   = "True"
  virtual_lab_manager_use_credentials = "True"
  virtual_lab_manager_cors_origins    = ["http://localhost:3000"]

  virtual_lab_manager_admin_base_path      = "{}/app/virtual-lab/lab/{}/admin?panel=billing"
  virtual_lab_manager_deployment_namespace = "https://${local.primary_domain}"

  virtual_lab_manager_cross_project_resolvers = [
    "public/ephys",
    "public/thalamus",
    "public/ngv",
    "public/multi-vesicular-release",
    "public/hippocampus",
    "public/topological-sampling",
    "bbp/lnmce",
    "public/ngv-anatomy",
    "bbp-external/seu",
    "public/forge",
    "public/sscx",
    "bbp/mouselight",
    "public/morphologies",
    "neurosciencegraph/datamodels",
    "bbp/mmb-point-neuron-framework-model",
    "neurosciencegraph/data",
  ]
}

module "dashboards" {
  source = "./dashboards"

  aws_region = local.aws_region
  account_id = local.account_id

  private_load_balancer_id = local.private_alb_https_listener_arn
  private_load_balancer_target_suffixes = {
    "AccountingService"  = module.accounting_svc.private_lb_rule_suffix
    "SonataCellService"  = module.cells_svc.private_lb_rule_suffix
    "KGInference"        = module.kg_inference_api.private_lb_rule_suffix
    "ThumbnailGenerator" = module.thumbnail_generation_api.private_lb_rule_suffix
    "KeyCloak"           = module.cs.private_keycloak_lb_rule_suffix
    "NexusFusion"        = module.nexus.private_fusion_lb_rule_suffix
    "NexusDelta"         = module.nexus.private_delta_lb_rule_suffix
    "BlueNaaS"           = module.bluenaas_svc.private_lb_rule_suffix
    "CoreWebApp"         = module.core_webapp.private_lb_rule_suffix
    "VLabManager"        = module.virtual_lab_manager.private_arn_suffix
  }
}
