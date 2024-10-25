locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id

  public_alb_https_listener_arn  = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  private_alb_https_listener_arn = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  public_alb_sg_id = data.terraform_remote_state.common.outputs.public_alb_sg_id
  domain_zone_id   = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id   = data.terraform_remote_state.common.outputs.nat_gateway_id

  vpc_cidr_block    = data.terraform_remote_state.common.outputs.vpc_cidr_block
  vpc_default_sg_id = data.terraform_remote_state.common.outputs.vpc_default_sg_id

  primary_domain = data.terraform_remote_state.common.outputs.primary_domain
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
  public_alb_https_listener_arn  = local.public_alb_https_listener_arn
  private_alb_https_listener_arn = local.private_alb_https_listener_arn

  preferred_hostname = local.primary_domain
  redirect_hostnames = ["openbluebrain.ch", "openbrainplatform.org", "openbrainplatform.com"]

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  account_id                    = local.account_id
}

module "ml" {
  source = "./ml"

  aws_region = local.aws_region
  account_id = local.account_id

  vpc_id                         = local.vpc_id
  vpc_cidr_block                 = local.vpc_cidr_block
  route_table_private_subnets_id = local.route_table_private_subnets_id

  dockerhub_credentials_arn = module.dockerhub_secret.dockerhub_credentials_arn
  backend_image_url         = "bluebrain/scholarag:v0.0.6"
  etl_image_url             = "bluebrain/scholaretl:v0.0.5"
  agent_image_url           = "bluebrain/neuroagent:v0.1.1"
  grobid_image_url          = "lfoppiano/grobid:0.8.0"

  paper_bucket_name = "ml-paper-bucket"

  alb_security_group_id = local.public_alb_sg_id
  alb_listener_arn      = local.public_alb_https_listener_arn

  private_alb_security_group_id    = data.terraform_remote_state.common.outputs.private_alb_security_group_id
  private_alb_listener_arn         = data.terraform_remote_state.common.outputs.private_alb_listener_3000_arn
  generic_private_alb_listener_arn = local.private_alb_https_listener_arn
  private_alb_dns                  = data.terraform_remote_state.common.outputs.private_alb_dns_name
}

module "nexus" {
  source = "./nexus"

  aws_region         = local.aws_region
  account_id         = local.account_id
  vpc_id             = local.vpc_id
  dockerhub_password = var.nise_dockerhub_password

  domain_zone_id = local.domain_zone_id
  nat_gateway_id = local.nat_gateway_id

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  nexus_obp_bucket_name = "nexus-obp-production"

  public_load_balancer_dns_name = data.terraform_remote_state.common.outputs.public_alb_dns_name
  public_lb_listener_https_arn  = local.public_alb_https_listener_arn
  private_lb_listener_https_arn = local.private_alb_https_listener_arn
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
  alb_listener_arn         = local.public_alb_https_listener_arn
  private_alb_listener_arn = local.private_alb_https_listener_arn

  # TODO remove after migrations
  aws_lb_alb_arn                 = data.terraform_remote_state.common.outputs.public_alb_arn
  aws_security_group_alb_id      = local.public_alb_sg_id
  route_table_private_subnets_id = local.route_table_private_subnets_id
}

module "cells_svc" {
  source = "./cells_svc"

  aws_region = local.aws_region

  vpc_id         = local.vpc_id
  vpc_cidr_block = local.vpc_cidr_block

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  public_alb_https_listener_arn  = local.public_alb_https_listener_arn
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_private_subnets_id = local.route_table_private_subnets_id

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
  alb_listener_arn           = local.public_alb_https_listener_arn
  private_alb_listener_arn   = local.private_alb_https_listener_arn
  alb_listener_rule_priority = 750
  internet_access_route_id   = local.route_table_private_subnets_id

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
}

module "static-server" {
  source = "./static-server"

  aws_region                 = local.aws_region
  account_id                 = local.account_id
  vpc_id                     = local.vpc_id
  public_subnet_ids          = [data.terraform_remote_state.common.outputs.public_a_subnet_id, data.terraform_remote_state.common.outputs.public_b_subnet_id]
  domain_name                = local.primary_domain
  static_content_bucket_name = local.primary_domain
  alb_listener_arn           = local.public_alb_https_listener_arn
  alb_listener_rule_priority = 600
}

module "core_webapp" {
  source = "./core_webapp"

  core_webapp_log_group_name           = "core_webapp"
  vpc_id                               = local.vpc_id
  core_webapp_ecs_number_of_containers = 1
  public_alb_https_listener_arn        = local.public_alb_https_listener_arn
  private_alb_https_listener_arn       = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  aws_region                           = local.aws_region
  account_id                           = local.account_id
  core_webapp_docker_image_url         = "bluebrain/sbo-core-web-app:latest"
  dockerhub_access_iam_policy_arn      = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn            = module.dockerhub_secret.dockerhub_credentials_arn
  core_webapp_base_path                = "/mmb-beta"
  route_table_id                       = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks        = ["0.0.0.0/0"]
  vpc_cidr_block                       = local.vpc_cidr_block

  env_DEBUG                               = "true"
  env_NEXTAUTH_URL                        = "https://${local.primary_domain}/mmb-beta/api/auth"
  env_KEYCLOAK_ISSUER                     = "https://${local.primary_domain}/auth/realms/SBO"
  env_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY  = "pk_test_51P6uAFFE4Bi50cLlatJIc0fUPsP0jQkaCCJ8TTkIYOOLIrLzxX1M9p1kVD11drNqsF9p7yiaumWJ8UHb3ptJJRXB00y3qjYReV"
  env_NEXT_PUBLIC_BBS_ML_PRIVATE_BASE_URL = "http://${data.terraform_remote_state.common.outputs.private_alb_dns_name}:3000/api/literature"
}

module "accounting_svc" {
  source = "./accounting_svc"

  aws_region                    = local.aws_region
  account_id                    = local.account_id
  vpc_id                        = local.vpc_id
  alb_listener_arn              = local.public_alb_https_listener_arn
  private_alb_listener_arn      = local.private_alb_https_listener_arn
  internet_access_route_id      = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks = [var.epfl_cidr, var.bbp_dmz_cidr, local.vpc_cidr_block, ]

  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn
  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn

  root_path = "/api/accounting"
}

module "kg_inference_api" {
  source = "./kg-inference-api"

  # public_alb_dns_name           = data.terraform_remote_state.common.outputs.public_alb_dns_name
  # domain_zone_id                = local.domain_zone_id
  public_alb_https_listener_arn  = local.public_alb_https_listener_arn
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

  #public_alb_dns_name           = data.terraform_remote_state.common.outputs.public_alb_dns_name
  #domain_zone_id                = local.domain_zone_id
  public_alb_https_listener_arn  = local.public_alb_https_listener_arn
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

  vpc_id                        = local.vpc_id
  aws_region                    = local.aws_region
  account_id                    = local.account_id
  vpc_cidr_block                = local.vpc_cidr_block
  nat_gateway_id                = local.nat_gateway_id
  allowed_source_ip_cidr_blocks = [local.vpc_cidr_block]
  public_lb_listener_https_arn  = local.public_alb_https_listener_arn
  private_lb_listener_https_arn = local.private_alb_https_listener_arn

  invite_link = "https://${local.primary_domain}/mmb-beta"
  mail_from   = "noreply@${local.primary_domain}"

  virtual_lab_manager_postgres_db   = "vlm"
  virtual_lab_manager_postgres_user = "vlm_user"
  core_subnets                      = [aws_subnet.core_svc_a.id, aws_subnet.core_svc_b.id]

  log_group_name = var.virtual_lab_manager_log_group_name

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  virtual_lab_manager_docker_image_url = var.virtual_lab_manager_docker_image_url

  keycloak_server_url = "https://${local.primary_domain}/auth/"

  virtual_lab_manager_secrets_arn = "arn:aws:secretsmanager:${local.aws_region}:${local.account_id}:secret:virtual_lab_manager-2Axecx"

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

  virtual_lab_manager_admin_base_path      = "{}/mmb-beta/virtual-lab/lab/{}/admin?panel=billing"
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

  load_balancer_id         = local.public_alb_https_listener_arn
  private_load_balancer_id = local.private_alb_https_listener_arn
  load_balancer_target_suffixes = {
    "AccountingService"  = module.accounting_svc.lb_rule_suffix
    "SonataCellService"  = module.cells_svc.lb_rule_suffix
    "KGInference"        = module.kg_inference_api.lb_rule_suffix
    "ThumbnailGenerator" = module.thumbnail_generation_api.lb_rule_suffix
    "KeyCloak"           = module.cs.keycloak_lb_rule_suffix
    "NexusFusion"        = module.nexus.fusion_lb_rule_suffix
    "NexusDelta"         = module.nexus.delta_lb_rule_suffix
    "BlueNaaS"           = module.bluenaas_svc.lb_rule_suffix
    "CoreWebApp"         = module.core_webapp.lb_rule_suffix
    "VLabManager"        = module.virtual_lab_manager.arn_suffix
  }
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
