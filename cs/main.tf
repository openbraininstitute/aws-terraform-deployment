module "networking" {
  source         = "./networking"
  vpc_id         = var.vpc_id
  route_table_id = var.route_table_id
}

module "keycloak" {
  source = "./keycloak"
  private_subnets = module.networking.keycloak_private_subnets
  vpc_id = var.vpc_id
  db_instance_class = var.db_instance_class
}
