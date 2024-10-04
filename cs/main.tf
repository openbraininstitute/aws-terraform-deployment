module "networking" {
  source         = "./networking"
  vpc_id         = var.vpc_id
  route_table_id = var.route_table_id
}

module "keycloak" {
  source                        = "./keycloak"
  private_subnets               = module.networking.keycloak_private_subnets
  vpc_id                        = var.vpc_id
  db_instance_class             = var.db_instance_class
  public_alb_https_listener_arn = var.public_alb_https_listener_arn

  preferred_hostname = var.preferred_hostname
  redirect_hostnames = var.redirect_hostnames

  efs_mt_subnets = module.networking.keycloak_private_subnets

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks

  aws_region = var.aws_region
  account_id = var.account_id
}
