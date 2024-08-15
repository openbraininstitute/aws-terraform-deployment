module "postgres_cluster" {
  source = "./postgres_cluster"

  providers = {
    aws = aws.nexus_postgres_tags
  }

  cluster_identifier = "nexus"
  subnets_ids        = module.networking.psql_subnets_ids
  security_group_id  = module.networking.main_subnet_sg_id
  instance_class     = "db.m5d.large"

  aws_region = var.aws_region
}
