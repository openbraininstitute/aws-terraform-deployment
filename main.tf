module "nexus" {
  source = "./nexus"

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
  vpc_id         = data.terraform_remote_state.common.outputs.vpc_id

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn

  domain_zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id

  allowed_source_ip_cidr_blocks = [var.epfl_cidr, data.terraform_remote_state.common.outputs.vpc_cidr_block]

  aws_lb_alb_dns_name           = data.terraform_remote_state.common.outputs.public_alb_dns_name
  aws_lb_listener_sbo_https_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id
}

module "viz" {
  source = "./viz"

  aws_region = var.aws_region
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn

  domain_zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id

  aws_lb_alb_arn                 = aws_lb.alb.arn
  aws_security_group_alb_id      = aws_security_group.alb.id
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}
