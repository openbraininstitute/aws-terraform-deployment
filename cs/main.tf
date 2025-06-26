module "networking" {
  source                         = "./networking"
  vpc_id                         = var.vpc_id
  route_table_private_subnets_id = var.route_table_private_subnets_id
}

# dedicated instance for Polina's Metabolism notebook
module "jupyterhub_metabolism" {
  source                            = "./jupyterhub"
  aws_coreservices_ssh_key_id       = var.aws_coreservices_ssh_key_id
  vpc_id                            = var.vpc_id
  private_alb_https_listener_arn    = var.private_alb_https_listener_arn
  primary_domain                    = var.domain_name
  jupyterhub_private_subnet         = module.networking.jupyterhub_private_subnet
  jupyterhub_ec2_type               = "c7i.large"
  jupyterhub_nginx_port             = 80
  jupyterhub_port                   = 8080
  jupyterhub_base_path              = "/jupyterhub_metabolism"
  jupyterhub_secrets_arn            = var.jupyterhub_secrets_arn
  jupyterhub_ec2_config_template    = "jupyterhub_metabolism_config.sh.tpl"
  jupyterhub_ec2_operating_system   = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250516"
  jupyterhub_sg_name                = "jupyterhub-metabolism-sg"
  jupyterhub_sg_efs_name            = "jupyterhub-metabolism-homedirs"
  jupyterhub_target_group_name      = "jupyterhub-metabolism-tg"
  jupyterhub_admin_users            = ["NataliBZ", "AurelienJaquier", "danielaegassan", "chr-pok", "dkeller9", "ilkilic", "james-isbister", "darshanmandge", "lidakanari", "mwolfr", "romani79", "danifr"]
  jupyterhub_listener_rule_priority = 350
}

module "jupyterhub" {
  source                            = "./jupyterhub"
  aws_coreservices_ssh_key_id       = var.aws_coreservices_ssh_key_id
  vpc_id                            = var.vpc_id
  private_alb_https_listener_arn    = var.private_alb_https_listener_arn
  primary_domain                    = var.domain_name
  jupyterhub_private_subnet         = module.networking.jupyterhub_private_subnet
  jupyterhub_ec2_type               = var.jupyterhub_ec2_type
  jupyterhub_nginx_port             = 80
  jupyterhub_port                   = 8080
  jupyterhub_base_path              = "/jupyterhub"
  jupyterhub_secrets_arn            = var.jupyterhub_secrets_arn
  jupyterhub_ec2_config_template    = "jupyterhub_config.sh.tpl"
  jupyterhub_ec2_operating_system   = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250530"
  jupyterhub_sg_name                = "jupyterhub-svc-sg"
  jupyterhub_sg_efs_name            = "jupyterhub-svc-homedirs"
  jupyterhub_target_group_name      = "jupyterhub-svc-tg"
  jupyterhub_admin_users            = ["NataliBZ", "AurelienJaquier", "danielaegassan", "chr-pok", "dkeller9", "ilkilic", "james-isbister", "darshanmandge", "lidakanari", "mwolfr", "romani79", "danifr"]
  jupyterhub_listener_rule_priority = 351
}

module "keycloak" {
  source                         = "./keycloak"
  private_subnets                = module.networking.keycloak_private_subnets
  vpc_id                         = var.vpc_id
  db_instance_class              = var.db_instance_class
  private_alb_https_listener_arn = var.private_alb_https_listener_arn

  domain_name      = var.domain_name
  keycloak_subnets = module.networking.keycloak_private_subnets

  keycloak_secrets_arn     = var.keycloak_secrets_arn
  keycloak_port            = 8081
  keycloak_management_port = 9000
  keycloak_task_size       = var.keycloak_task_size

  keycloak_ecs_cluster_name = "keycloak-cluster"
  keycloak_ecs_service_name = "keycloak-service"

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks
}
