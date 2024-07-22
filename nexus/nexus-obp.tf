locals {
  environment = "nexusobp"
}

module "postgres_aurora" {
  source = "./postgres_aurora"

  providers = {
    aws             = aws.nexus_postgres_tags
  }

  nexus_postgresql_name          = local.environment
  nexus_postgresql_database_name = local.environment
  nexus_database_username        = local.environment
  subnets_ids           = module.networking.psql_subnets_ids
  security_group_id     = module.networking.main_subnet_sg_id
  vpc_id                = var.vpc_id
}