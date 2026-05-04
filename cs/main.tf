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
  jupyterhub_ec2_operating_system   = "ami-0a7d80731ae1b2435"
  jupyterhub_sg_name                = "jupyterhub-metabolism-sg"
  jupyterhub_sg_efs_name            = "jupyterhub-metabolism-homedirs"
  jupyterhub_target_group_name      = "jupyterhub-metabolism-tg"
  jupyterhub_admin_users            = ["NataliBZ", "AurelienJaquier", "chr-pok", "dkeller9", "ilkilic", "james-isbister", "darshanmandge", "lidakanari", "mwolfr", "romani79", "danifr"]
  jupyterhub_listener_rule_priority = 350
}

# Small part of the setup of the EKS cluster for JupyterHub
# Just fyi to avoid confusion: there's also cs/jupyterhub/ which defines
# the single EC2 VM with a JupyterHub for Polina's metabolism notebook
module "jupyterhub_eks" {
  source = "./jupyterhub_eks"

  jupyterhub_eks_public_a_cidr  = "10.0.31.0/25"
  jupyterhub_eks_public_b_cidr  = "10.0.31.128/25"
  jupyterhub_eks_private_a_cidr = "10.0.32.0/23"
  jupyterhub_eks_private_b_cidr = "10.0.34.0/23"

  vpc_id         = var.vpc_id
  aws_region     = var.aws_region
  vpc_cidr_block = var.vpc_cidr_block
  nat_gateway_id = var.nat_gateway_id

  route_table_private_subnets_id = var.route_table_private_subnets_id
  route_table_public_subnets_id  = var.route_table_public_subnets_id
  aws_endpoints_subnet_cidr      = var.aws_endpoints_subnet_cidr

  jupyterhub_eks_cluster_name = "jupyterhub"
  private_alb_cidr_a          = var.private_alb_cidr_a
  private_alb_cidr_b          = var.private_alb_cidr_b
  notebook_service_cidr_a     = var.notebook_service_cidr_a
  notebook_service_cidr_b     = var.notebook_service_cidr_b

  is_staging = var.is_staging

  public_data_efs_ip_address1_as_cidr = var.public_data_efs_ip_address1_as_cidr
  public_data_efs_ip_address2_as_cidr = var.public_data_efs_ip_address2_as_cidr
  bastion_instance_private_ip         = var.bastion_instance_private_ip

  keycloak_subnet_cidr_a = module.networking.keycloak_subnet_cidr_a
  keycloak_subnet_cidr_b = module.networking.keycloak_subnet_cidr_b

  # Only used in staging
  is_lustre_filesystem_enabled = false
  # As a test, mount the s3 bucket with the shared data for jupyterhub
  s3_bucket_name = "jupyterhub-s3-shared-volume"
  # Also mount the /pubic part of the s3 bucket containing the entitycore data
  s3_bucket_entitycore_data_name = "entitycore-data-staging"
}

module "filesystems_test_vm" {
  count  = 0
  source = "./filesystems_test_vm"

  ec2_type                           = "m6i.large"
  jupyterhub_eks_private_a_subnet_id = module.jupyterhub_eks.private_subnet_a_id
  jupyterhub_eks_private_b_subnet_id = module.jupyterhub_eks.private_subnet_b_id
  aws_coreservices_ssh_key_id        = var.aws_coreservices_ssh_key_id
  vpc_id                             = var.vpc_id
  public_data_efs_arn                = var.public_data_efs_arn
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

module "secret_sharing_svc" {
  count                          = var.is_staging ? 1 : 0 # only deployed in staging
  source                         = "./secret_sharing_svc"
  vpc_id                         = var.vpc_id
  private_alb_https_listener_arn = var.private_alb_https_listener_arn

  secret_sharing_svc_hostname               = "secrets.openbraininstitute.org"
  secret_sharing_svc_port                   = 8787
  secret_sharing_svc_listener_rule_priority = 571
  secret_sharing_svc_subnet                 = module.networking.secret_sharing_svc_private_subnet
  secret_sharing_svc_task_size = {
    cpu    = 256
    memory = 512
  }
}
