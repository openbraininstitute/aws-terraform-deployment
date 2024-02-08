module "networking" {
  source = "./networking"

  aws_region     = var.aws_region
  nat_gateway_id = var.nat_gateway_id
  vpc_id         = var.vpc_id
}

module "postgres" {
  source = "./postgres"

  subnets_ids              = module.networking.psql_subnets_ids
  subnet_security_group_id = module.networking.main_subnet_sg_id
  instance_class           = "db.t3.small"
}

module "elasticsearch" {
  source = "./elasticsearch"

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id
}

module "blazegraph" {
  source = "./blazegraph"

  aws_region                    = var.aws_region
  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  subnet_id                     = module.networking.subnet_id
  subnet_security_group_id      = module.networking.main_subnet_sg_id
  private_blazegraph_hostname   = var.private_blazegraph_hostname
  private_alb_listener_9999_arn = var.private_alb_listener_9999_arn
  ecs_cluster_arn               = aws_ecs_cluster.nexus.arn
}

module "storage" {
  source = "./storage"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id
  ecs_cluster_arn          = aws_ecs_cluster.nexus.arn
  ecs_cluster_name         = aws_ecs_cluster.nexus.name
  amazon_linux_ecs_ami_id  = var.amazon_linux_ecs_ami_id
}

module "delta" {
  source = "./delta"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id
  ecs_cluster_arn          = aws_ecs_cluster.nexus.arn

  aws_lb_target_group_nexus_app_arn = aws_lb_target_group.nexus_app.arn
  dockerhub_access_iam_policy_arn   = var.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn         = var.dockerhub_credentials_arn

  # TODO once possible, this module should also take in (at least) the following:
  # - the postgres db address
  # - the elasticsearch address
  # - the blazegraph address
}
