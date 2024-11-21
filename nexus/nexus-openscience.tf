locals {
  openscience_database_id = "nexus-openscience-db"
}

module "postgres_cluster_openscience" {
  source = "./postgres_cluster"

  providers = {
    aws = aws.nexus_openscience_postgres_tags
  }

  cluster_identifier              = local.openscience_database_id
  subnets_ids                     = module.networking.psql_subnets_ids
  security_group_id               = module.networking.main_subnet_sg_id
  instance_class                  = "db.m5d.large"
  nexus_postgresql_engine_version = "16"
  nexus_secrets_arn               = var.nexus_secrets_arn
}
