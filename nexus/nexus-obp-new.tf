module "postgres_cluster_obp" {
  source = "./postgres_cluster"

  providers = {
    aws = aws.nexus_postgres_tags
  }

  cluster_identifier              = "nexus-obp-db"
  subnets_ids                     = module.networking.psql_subnets_ids
  security_group_id               = module.networking.main_subnet_sg_id
  instance_class                  = "db.m5d.large"
  nexus_postgresql_engine_version = "16"

  aws_region = var.aws_region
}