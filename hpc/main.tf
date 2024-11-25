terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      SBO_Billing  = var.sbo_billing
      "obp:module" = var.sbo_billing
    }
  }
  region = var.aws_region
}


module "vpc" {
  source = "./vpc"

  obp_vpc_id = var.obp_vpc_id
}

module "networking" {
  source = "./networking"

  pcluster_vpc_id           = module.vpc.pcluster_vpc_id
  obp_vpc_id                = var.obp_vpc_id
  vpc_peering_connection_id = module.vpc.peering_connection_id
  aws_region                = var.aws_region
  create_slurmdb            = var.create_slurmdb
  create_jumphost           = var.create_jumphost
  compute_nat_access        = var.compute_nat_access
  compute_subnet_count      = var.compute_subnet_count
  av_zone_suffixes          = var.av_zone_suffixes
  peering_route_tables      = var.peering_route_tables
  security_groups           = [module.security.compute_hpc_sg_id]
  lambda_subnet_cidr        = var.lambda_subnet_cidr
  endpoints_route_table_id  = var.endpoints_route_table_id
}

module "security" {
  source = "./security"

  pcluster_vpc_id           = module.vpc.pcluster_vpc_id
  obp_vpc_id                = var.obp_vpc_id
  create_jumphost           = var.create_jumphost
  create_slurmdb            = var.create_slurmdb
  account_id                = var.account_id
  aws_region                = var.aws_region
  aws_endpoints_subnet_cidr = var.aws_endpoints_subnet_cidr
}

module "slurmdb" {
  source = "./slurmdb"

  slurm_mysql_admin_username = var.slurm_mysql_admin_username
  slurm_db_subnets_ids       = module.networking.slurm_db_subnets_ids
  slurm_db_sg_id             = module.security.slurm_db_sg_id
  create_slurmdb             = var.create_slurmdb
  hpc_slurm_secrets_arn      = var.hpc_slurm_secrets_arn
}

module "compute-cluster" {
  source = "./compute-cluster"

  aws_region                = var.aws_region
  account_id                = var.account_id
  sbo_billing               = var.sbo_billing
  domain_zone_id            = var.domain_zone_id
  compute_subnet_public_id  = module.networking.compute_subnet_public_id
  compute_subnet_id         = var.create_compute_instances ? module.networking.compute_subnet_ids[0] : ""
  compute_hpc_sg_id         = module.security.compute_hpc_sg_id
  jumphost_sg_id            = module.security.jumphost_sg_id
  create_jumphost           = var.create_jumphost
  create_compute_instances  = var.create_compute_instances
  num_compute_instances     = var.num_compute_instances
  compute_instance_type     = var.compute_instance_type
  efs_mount_target_dns_name = module.efs.efs_mount_target_dns_name
}

module "efs" {
  source = "./efs"

  compute_efs_sg_id      = module.security.compute_efs_sg_id
  compute_subnet_efs_ids = module.networking.compute_subnet_efs_ids
  av_zone_suffixes       = var.av_zone_suffixes
}

module "resource-provisioner" {
  source = "./resource-provisioner/"

  hpc_resource_provisioner_role       = module.security.resource_provisioner_iam_role_arn
  hpc_resource_provisioner_subnet_ids = [module.networking.lambda_subnet_id]
  hpc_resource_provisioner_sg_ids     = [var.obp_vpc_default_sg_id, module.security.vpc_peering_security_group_id, module.security.resource_provisioner_security_group_id]
  aws_region                          = var.aws_region
  account_id                          = var.account_id
}

module "dynamodb" {
  source        = "./dynamodb/"
  is_production = var.is_production
}
