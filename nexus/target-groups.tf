module "sbo_delta_target_group" {
  source = "./delta_target_group"

  providers = {
    aws = aws.nexus_delta_tags
  }

  nexus_delta_hostname     = "sbo-nexus-delta.shapes-registry.org"
  target_group_prefix      = "nx-dlt"
  unique_listener_priority = 100

  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  public_load_balancer_dns_name = var.public_load_balancer_dns_name
  nat_gateway_id                = var.nat_gateway_id
  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks

  aws_region = var.aws_region
}

module "sbo_fusion_target_group" {
  source = "./fusion_target_group"

  providers = {
    aws = aws.nexus_fusion_tags
  }

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

