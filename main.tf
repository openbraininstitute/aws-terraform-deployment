module "ml" {
  source = "./ml"

  aws_region = data.terraform_remote_state.common.outputs.aws_region
  account_id = data.aws_caller_identity.current.account_id

  vpc_id                         = data.terraform_remote_state.common.outputs.vpc_id
  vpc_cidr_block                 = data.terraform_remote_state.common.outputs.vpc_cidr_block
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  dockerhub_credentials_arn = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
  backend_image_url         = "bluebrain/bbs-pipeline:v0.18.0"
  etl_image_url             = "bluebrain/bbs-etl:parse-v1.8.2"
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

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn

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

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
  secret_dockerhub_arn            = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn

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

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn

  domain_zone_id = data.terraform_remote_state.common.outputs.domain_zone_id

  public_alb_https_listener_arn  = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  public_alb_dns_name            = data.terraform_remote_state.common.outputs.public_alb_dns_name
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  aws_coreservices_ssh_key_id = data.terraform_remote_state.common.outputs.aws_coreservices_ssh_key_id

  epfl_cidr = var.epfl_cidr

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id
}

module "nse" {
  source = "./nse"

  aws_region                = var.aws_region
  account_id                = data.aws_caller_identity.current.account_id
  vpc_id                    = data.terraform_remote_state.common.outputs.vpc_id
  dockerhub_credentials_arn = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
  amazon_linux_ecs_ami_id   = data.aws_ami.amazon_linux_2_ecs.id
  route_table_id            = data.terraform_remote_state.common.outputs.route_table_private_subnets_id

  docker_image_url = "bluebrain/blue-naas-single-cell:latest"
}
