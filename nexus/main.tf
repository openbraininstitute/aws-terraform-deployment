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

module "elasticcloud" {
  source = "./elasticcloud"

  aws_region      = var.aws_region
  vpc_id          = var.vpc_id
  subnet_ids      = [module.networking.subnet_b_id]
  deployment_name = "nexus-es"
}

module "blazegraph" {
  source = "./blazegraph"

  aws_region               = var.aws_region
  vpc_id                   = var.vpc_id
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
}

module "delta" {
  source = "./delta"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = aws_iam_role.nexus_ecs_task_execution.arn
  nexus_secrets_arn                        = var.nexus_secrets_arn

  aws_lb_target_group_nexus_app_arn = aws_lb_target_group.nexus_app.arn
  dockerhub_credentials_arn         = var.dockerhub_credentials_arn

  postgres_host          = module.postgres.host
  elasticsearch_endpoint = module.elasticcloud.http_endpoint
  blazegraph_endpoint    = "http://${module.blazegraph.blazebraph_dns_name}:9999/blazegraph"
}

module "fusion" {
  source = "./fusion"

  nexus_fusion_hostname = var.nexus_fusion_hostname
  nexus_delta_hostname  = var.nexus_delta_hostname

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_fusion_arn = aws_lb_target_group.nexus_fusion.arn
  dockerhub_access_iam_policy_arn      = var.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn            = var.dockerhub_credentials_arn
}

module "ship" {
  source = "./ship"

  dockerhub_credentials_arn   = var.dockerhub_credentials_arn
  ecs_task_execution_role_arn = aws_iam_role.nexus_ecs_task_execution.arn
  nexus_secrets_arn           = var.nexus_secrets_arn
  postgres_host               = module.postgres.host
}

moved {
  from = module.delta.aws_iam_policy.sbo_nexus_app_secrets_access
  to   = aws_iam_policy.nexus_secrets_access
}