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

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  target_group_prefix           = "obpdlt"
  unique_listener_priority      = 104
  nat_gateway_id                = var.nat_gateway_id
  vpc_id                        = var.vpc_id
}

module "obp_delta_target_group_2" {
  source = "./path_target_group"

  providers = {
    aws = aws.nexus_delta_tags
  }

  target_port       = 8080
  base_path         = "/api/nexus2"
  health_check_path = "/api/nexus2/v1/version"
  health_check_code = "200-499"

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
  public_lb_listener_https_arn  = var.public_lb_listener_https_arn
  target_group_prefix           = "nxdt2"
  unique_listener_priority      = 111
  nat_gateway_id                = var.nat_gateway_id
  vpc_id                        = var.vpc_id
}


