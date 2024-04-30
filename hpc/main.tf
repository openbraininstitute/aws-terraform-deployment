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
      "obp:module" = "hpc"
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
  vpc_peering_connection_id = module.vpc.peering_connection_id
  aws_region                = var.aws_region
  create_compute_instances  = var.create_compute_instances
  create_slurmdb            = var.create_slurmdb
  create_jumphost           = var.create_jumphost
  compute_nat_access        = var.compute_nat_access
  compute_subnet_count      = var.compute_subnet_count
  av_zone_suffixes          = var.av_zone_suffixes
  peering_route_tables      = var.peering_route_tables
  existing_route_targets    = var.existing_route_targets
  security_groups           = [module.security.compute_hpc_sg_id]
}

module "security" {
  source = "./security"

  pcluster_vpc_id          = module.vpc.pcluster_vpc_id
  obp_vpc_id               = var.obp_vpc_id
  create_compute_instances = var.create_compute_instances
  create_jumphost          = var.create_jumphost
  create_slurmdb           = var.create_slurmdb
  slurm_db_a_subnet_id     = module.networking.slurm_db_a_subnet_id
}

module "slurmdb" {
  source = "./slurmdb"

  slurm_mysql_admin_username = var.slurm_mysql_admin_username
  slurm_mysql_admin_password = var.slurm_mysql_admin_password
  slurm_db_subnets_ids       = module.networking.slurm_db_subnets_ids
  slurm_db_sg_id             = module.security.slurm_db_sg_id
  create_slurmdb             = var.create_slurmdb
}

module "compute-cluster" {
  source = "./compute-cluster"

  aws_region               = var.aws_region
  compute_subnet_public_id = module.networking.compute_subnet_public_id
  compute_subnet_id        = var.create_compute_instances ? module.networking.compute_subnet_ids[0] : ""
  compute_hpc_sg_id        = module.security.compute_hpc_sg_id
  jumphost_sg_id           = module.security.jumphost_sg_id
  create_jumphost          = var.create_jumphost
  create_compute_instances = var.create_compute_instances
  num_compute_instances    = var.num_compute_instances
  compute_instance_type    = var.compute_instance_type
}

module "efs" {
  source = "./efs"

  aws_region               = var.aws_region
  compute_subnet_a_id      = var.create_compute_instances ? module.networking.compute_subnet_ids[0] : ""
  compute_efs_sg_id        = module.security.compute_efs_sg_id
  create_compute_instances = var.create_compute_instances
  compute_subnet_ids       = module.networking.compute_subnet_ids
  compute_subnet_efs_ids   = module.networking.compute_subnet_efs_ids
  av_zone_suffixes         = var.av_zone_suffixes
}
