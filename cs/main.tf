module "networking" {
  source         = "./networking"
  vpc_id         = var.vpc_id
  route_table_id = var.route_table_id
}

module "keycloak" {
  source                  = "./keycloak"
  private_subnets         = module.networking.keycloak_private_subnets
  vpc_id                  = var.vpc_id
  db_instance_class       = var.db_instance_class
  public_alb_listener     = var.public_alb_listener
  primary_auth_hostname   = var.primary_auth_hostname
  secondary_auth_hostname = var.secondary_auth_hostname
  efs_mt_subnets          = module.networking.keycloak_private_subnets

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
}
