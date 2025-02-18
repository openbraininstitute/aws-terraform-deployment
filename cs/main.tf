module "networking" {
  source                         = "./networking"
  vpc_id                         = var.vpc_id
  route_table_private_subnets_id = var.route_table_private_subnets_id
}

module "jupyterhub" {
  source                         = "./jupyterhub"
  aws_coreservices_ssh_key_id    = var.aws_coreservices_ssh_key_id
  vpc_id                         = var.vpc_id
  private_alb_https_listener_arn = var.private_alb_https_listener_arn
  primary_domain                 = var.preferred_hostname
  jupyterhub_private_subnet      = module.networking.jupyterhub_private_subnet
  jupyterhub_port                = 80
  jupyterhub_base_path           = "/jupyterhub"
  jupyterhub_secrets_arn         = var.jupyterhub_secrets_arn
}

module "keycloak" {
  source                         = "./keycloak"
  private_subnets                = module.networking.keycloak_private_subnets
  vpc_id                         = var.vpc_id
  db_instance_class              = var.db_instance_class
  private_alb_https_listener_arn = var.private_alb_https_listener_arn

  preferred_hostname = var.preferred_hostname
  redirect_hostnames = var.redirect_hostnames

  efs_mt_subnets = module.networking.keycloak_private_subnets

  keycloak_secrets_arn     = var.keycloak_secrets_arn
  keycloak_port            = 8081
  keycloak_management_port = 9000
  keycloak_task_size       = var.keycloak_task_size

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
}
