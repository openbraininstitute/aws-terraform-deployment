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
  deployment_name = "nexus_es"
}

module "elasticsearch" {
  source = "./elasticsearch"

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id
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

module "storage" {
  source = "./storage"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  ecs_cluster_name                         = aws_ecs_cluster.nexus.name
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  amazon_linux_ecs_ami_id                  = var.amazon_linux_ecs_ami_id
}

module "delta" {
  source = "./delta"

  aws_region               = var.aws_region
  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_lb_target_group_nexus_app_arn = aws_lb_target_group.nexus_app.arn
  dockerhub_access_iam_policy_arn   = var.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn         = var.dockerhub_credentials_arn

  # TODO once possible, this module should also take in (at least) the following:
  # - the postgres db address
  # - the elasticsearch address
  # - the blazegraph address
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

moved {
  from = aws_cloudwatch_log_group.nexus_fusion
  to   = module.fusion.aws_cloudwatch_log_group.nexus_fusion
}

moved {
  from = aws_ecs_service.nexus_fusion_ecs_service[0]
  to   = module.fusion.aws_ecs_service.nexus_fusion_ecs_service[0]
}

moved {
  from = aws_ecs_task_definition.nexus_fusion_ecs_definition[0]
  to   = module.fusion.aws_ecs_task_definition.nexus_fusion_ecs_definition[0]
}

moved {
  from = aws_iam_role.ecs_nexus_fusion_task_execution_role[0]
  to   = module.fusion.aws_iam_role.ecs_nexus_fusion_task_execution_role[0]
}

moved {
  from = aws_iam_role.ecs_nexus_fusion_task_role[0]
  to   = module.fusion.aws_iam_role.ecs_nexus_fusion_task_role[0]
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_fusion_task_execution_role_policy_attachment[0]
  to   = module.fusion.aws_iam_role_policy_attachment.ecs_nexus_fusion_task_execution_role_policy_attachment[0]
}
