module "networking" {
  source = "./networking"

  aws_region     = var.aws_region
  nat_gateway_id = var.nat_gateway_id
  vpc_cidr_block = var.vpc_cidr_block
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
  vpc_cidr_block                = var.vpc_cidr_block
  vpc_id                        = var.vpc_id
  domain_zone_id                = var.domain_zone_id
  subnet_id                     = module.networking.subnet_id
  subnet_security_group_id      = module.networking.main_subnet_sg_id
  private_blazegraph_hostname   = var.private_blazegraph_hostname
  private_alb_listener_9999_arn = var.private_alb_listener_9999_arn
  ecs_cluster_arn               = aws_ecs_cluster.nexus.arn
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

# Delta moved blocks
moved {
  from = aws_cloudwatch_log_group.nexus_app
  to   = module.delta.aws_cloudwatch_log_group.nexus_app
}

moved {
  from = aws_ecs_service.nexus_app_ecs_service[0]
  to   = module.delta.aws_ecs_service.nexus_app_ecs_service[0]
}

moved {
  from = aws_ecs_task_definition.nexus_app_ecs_definition[0]
  to   = module.delta.aws_ecs_task_definition.nexus_app_ecs_definition[0]
}

moved {
  from = aws_efs_backup_policy.nexus_backup_policy
  to   = module.delta.aws_efs_backup_policy.nexus_backup_policy
}

moved {
  from = aws_efs_file_system.nexus_app_config
  to   = module.delta.aws_efs_file_system.nexus_app_config
}

moved {
  from = aws_efs_mount_target.efs_for_nexus_app
  to   = module.delta.aws_efs_mount_target.efs_for_nexus_app
}

moved {
  from = aws_iam_policy.sbo_nexus_app_secrets_access
  to   = module.delta.aws_iam_policy.sbo_nexus_app_secrets_access
}

moved {
  from = aws_iam_role.ecs_nexus_app_task_execution_role[0]
  to   = module.delta.aws_iam_role.ecs_nexus_app_task_execution_role[0]
}

moved {
  from = aws_iam_role.ecs_nexus_app_task_role[0]
  to   = module.delta.aws_iam_role.ecs_nexus_app_task_role[0]
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_app_secrets_access_policy_attachment[0]
  to   = module.delta.aws_iam_role_policy_attachment.ecs_nexus_app_secrets_access_policy_attachment[0]
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_app_task_execution_role_policy_attachment[0]
  to   = module.delta.aws_iam_role_policy_attachment.ecs_nexus_app_task_execution_role_policy_attachment[0]
}

# Blazegraph moved blocks
moved {
  from = aws_cloudwatch_log_group.blazegraph_app
  to   = module.blazegraph.aws_cloudwatch_log_group.blazegraph_app
}

moved {
  from = aws_ecs_service.blazegraph_ecs_service[0]
  to   = module.blazegraph.aws_ecs_service.blazegraph_ecs_service[0]
}

moved {
  from = aws_ecs_task_definition.blazegraph_ecs_definition[0]
  to   = module.blazegraph.aws_ecs_task_definition.blazegraph_ecs_definition[0]
}

moved {
  from = aws_efs_backup_policy.policy
  to   = module.blazegraph.aws_efs_backup_policy.policy
}

moved {
  from = aws_efs_file_system.blazegraph
  to   = module.blazegraph.aws_efs_file_system.blazegraph
}

moved {
  from = aws_efs_mount_target.efs_for_blazegraph
  to   = module.blazegraph.aws_efs_mount_target.efs_for_blazegraph
}

moved {
  from = aws_iam_role.ecs_blazegraph_task_execution_role[0]
  to   = module.blazegraph.aws_iam_role.ecs_blazegraph_task_execution_role[0]
}

moved {
  from = aws_iam_role_policy_attachment.ecs_blazegraph_task_execution_role_policy_attachment[0]
  to   = module.blazegraph.aws_iam_role_policy_attachment.ecs_blazegraph_task_execution_role_policy_attachment[0]
}

moved {
  from = aws_lb_listener_rule.blazegraph_9999
  to   = module.blazegraph.aws_lb_listener_rule.blazegraph_9999
}

moved {
  from = aws_lb_target_group.blazegraph
  to   = module.blazegraph.aws_lb_target_group.blazegraph
}

# ES moved blocks
moved {
  from = aws_cloudwatch_log_group.nexus_es
  to   = module.elasticsearch.aws_cloudwatch_log_group.nexus_es
}

moved {
  from = aws_security_group.nexus_es
  to   = module.networking.aws_security_group.main_subnet_sg
}

moved {
  from = aws_opensearch_domain.nexus_es
  to   = module.elasticsearch.aws_opensearch_domain.nexus_es
}

# Postgres moved blocks
moved {
  from = aws_subnet.nexus_db_a
  to   = module.networking.aws_subnet.nexus_db_a
}

moved {
  from = aws_subnet.nexus_db_b
  to   = module.networking.aws_subnet.nexus_db_b
}

moved {
  from = aws_network_acl.nexus_db
  to   = module.networking.aws_network_acl.nexus_db
}

moved {
  from = aws_db_instance.nexusdb[0]
  to   = module.postgres.aws_db_instance.nexusdb[0]
}

moved {
  from = aws_db_subnet_group.nexus_db_subnet_group
  to   = module.postgres.aws_db_subnet_group.nexus_db_subnet_group
}
