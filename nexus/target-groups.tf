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

module "obp_delta_target_group" {
  source = "./path_target_group"

  providers = {
    aws = aws.nexus_delta_tags
  }

  target_port       = 8080
  base_path         = "/api/nexus"
  health_check_path = "/api/nexus/v1/version"

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  target_group_prefix           = "obpdlt"
  unique_listener_priority      = 101
  nat_gateway_id                = var.nat_gateway_id
  vpc_id                        = var.vpc_id
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

module "obp_fusion_target_group" {
  source = "./path_target_group"

  providers = {
    aws = aws.nexus_fusion_tags
  }

  target_port       = 8000
  base_path         = "/web/fusion"
  health_check_path = "/web/fusion/status"

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  target_group_prefix           = "obpfus"
  unique_listener_priority      = 301
  nat_gateway_id                = var.nat_gateway_id
  vpc_id                        = var.vpc_id
}

module "delta_nginx_target_group" {
  source = "./path_target_group"

  target_port       = 8080
  base_path         = "/api/delta"
  health_check_path = "/api/delta/v1/version"
  health_check_code = "302"

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  target_group_prefix           = "obpdlt"
  unique_listener_priority      = 104
  nat_gateway_id                = var.nat_gateway_id
  vpc_id                        = var.vpc_id
}

