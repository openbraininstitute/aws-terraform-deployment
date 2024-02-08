module "nexus" {
  source = "./nexus"

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
  vpc_id         = data.terraform_remote_state.common.outputs.vpc_id

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn

  domain_zone_id                = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id                = data.terraform_remote_state.common.outputs.nat_gateway_id
  private_alb_dns_name          = data.terraform_remote_state.common.outputs.private_alb_dns_name
  private_alb_listener_9999_arn = data.terraform_remote_state.common.outputs.private_alb_listener_9999_arn

  aws_lb_alb_dns_name           = aws_lb.alb.dns_name
  aws_lb_listener_sbo_https_arn = aws_lb_listener.sbo_https.arn

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id
}
