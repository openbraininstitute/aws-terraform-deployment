module "postgres_aurora" {
  source = "./postgres_aurora"

  providers = {
    aws             = aws.nexus_postgres_tags
  }

  subnets_ids       = module.networking.psql_subnets_ids
  security_group_id = module.networking.main_subnet_sg_id
}