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
module "cs" {
  source = "./cs"
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  aws_region              = data.terraform_remote_state.common.outputs.aws_region
  route_table_id          = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
  db_instance_class       = "db.t3.micro"
  public_alb_listener     = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  primary_auth_hostname   = data.terraform_remote_state.common.outputs.primary_auth_hostname
  secondary_auth_hostname = data.terraform_remote_state.common.outputs.secondary_auth_hostname
  epfl_cidr = var.epfl_cidr
}
 
module "ml" {
  source = "./ml"

  aws_region = data.terraform_remote_state.common.outputs.aws_region
  account_id = data.aws_caller_identity.current.account_id

  vpc_id                         = data.terraform_remote_state.common.outputs.vpc_id
  vpc_cidr_block                 = data.terraform_remote_state.common.outputs.vpc_cidr_block
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  dockerhub_credentials_arn = module.dockerhub_secret.dockerhub_credentials_arn
  backend_image_url         = "bluebrain/bbs-pipeline:v0.18.1"
  etl_image_url             = "bluebrain/bbs-etl:parse-v1.8.3"
  grobid_image_url          = "lfoppiano/grobid:0.8.0"

  alb_security_group_id = data.terraform_remote_state.common.outputs.public_alb_sg_id
  alb_listener_arn      = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn

  private_alb_security_group_id = "sg-0a2007eb7704cc303"
  private_alb_listener_arn      = data.terraform_remote_state.common.outputs.private_alb_listener_3000_arn
  private_alb_dns               = data.terraform_remote_state.common.outputs.private_alb_dns_name

  secret_manager_arn = "arn:aws:secretsmanager:us-east-1:671250183987:secret:ml_secrets-uEWnHv"
}

module "nexus" {
  source = "./nexus"

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
  vpc_id         = data.terraform_remote_state.common.outputs.vpc_id

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  domain_zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id

  allowed_source_ip_cidr_blocks = [var.epfl_cidr, data.terraform_remote_state.common.outputs.vpc_cidr_block, data.terraform_remote_state.common.outputs.bbpproxy_cidr]

  aws_lb_alb_dns_name           = data.terraform_remote_state.common.outputs.public_alb_dns_name
  aws_lb_listener_sbo_https_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id
}

module "viz" {
  source = "./viz"

  aws_region = var.aws_region
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  secret_dockerhub_arn            = module.dockerhub_secret.dockerhub_credentials_arn

  domain_zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id

  aws_lb_alb_arn                 = data.terraform_remote_state.common.outputs.public_alb_arn
  aws_security_group_alb_id      = data.terraform_remote_state.common.outputs.public_alb_sg_id
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}

module "cells_svc" {
  source = "./cells_svc"

  aws_region = var.aws_region

  vpc_id         = data.terraform_remote_state.common.outputs.vpc_id
  vpc_cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block

  dockerhub_access_iam_policy_arn = module.dockerhub_secret.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = module.dockerhub_secret.dockerhub_credentials_arn

  domain_zone_id = data.terraform_remote_state.common.outputs.domain_zone_id

  public_alb_https_listener_arn  = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  public_alb_dns_name            = data.terraform_remote_state.common.outputs.public_alb_dns_name
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  aws_coreservices_ssh_key_id = module.coreservices_key.key_pair_id

  epfl_cidr = var.epfl_cidr

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id
}

module "nse" {
  source = "./nse"

  aws_region                = var.aws_region
  account_id                = data.aws_caller_identity.current.account_id
  vpc_id                    = data.terraform_remote_state.common.outputs.vpc_id
  dockerhub_credentials_arn = module.dockerhub_secret.dockerhub_credentials_arn
  amazon_linux_ecs_ami_id   = data.aws_ami.amazon_linux_2_ecs.id
  route_table_id            = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  docker_image_url = "bluebrain/blue-naas-single-cell:latest"
}

module "hpc" {
  source = "./hpc"

  aws_region                 = var.aws_region
  obp_vpc_id                 = "vpc-08aa04757a326969b"
  sbo_billing                = "hpc"
  slurm_mysql_admin_username = "slurm_admin"
  slurm_mysql_admin_password = "arn:aws:secretsmanager:us-east-1:671250183987:secret:hpc_slurm_db_password-6LNuBy"
  create_compute_instances   = false
  num_compute_instances      = 0
  create_slurmdb             = false # TODO-SLURMDB: re-enable when redeploying the cluster
  compute_instance_type      = "m7g.medium"
  create_jumphost            = false
  compute_nat_access         = false
  compute_subnet_count       = 16
  av_zone_suffixes           = ["a", "b", "c", "d"]
  peering_route_tables       = ["rtb-0e4eb2a1cbab24423"]
  existing_route_targets     = ["172.16.0.0/16"]
}

