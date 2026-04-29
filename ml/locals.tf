locals {
  ecs_cluster_arn    = module.ml_ecs_cluster.arn
  private_subnet_ids = [aws_subnet.ml_subnet_a.id, aws_subnet.ml_subnet_b.id]

  # When instance_key is empty, keep the original hardcoded resource names (no drift on module.ml).
  legacy = var.instance_key == ""

  ml_prefix = local.legacy ? "ml" : "ml-${var.instance_key}"

  ecs_cluster_name = "${local.ml_prefix}-ecs-cluster"

  rds_security_group_name   = local.legacy ? "ml-rds" : "${local.ml_prefix}-rds"
  rds_instance_identifier   = local.legacy ? "ml-rds-postgres" : "${local.ml_prefix}-rds-postgres"
  redis_security_group_name = local.legacy ? "redis-sg" : "${local.ml_prefix}-redis-sg"
  redis_subnet_group_name   = local.legacy ? "redis-subnet-group" : "${local.ml_prefix}-redis-subnet-group"

  # ElastiCache cluster_id max 20 characters.
  elasticache_cluster_id = local.legacy ? var.ec_cluster_name : substr(
    "redis-${replace(lower(var.instance_key), "_", "-")}",
    0,
    20
  )

  ecs_service_name = local.legacy ? "ecs-service-agent" : "${local.ml_prefix}-ecs-svc-agent"

  agent_container_name = local.legacy ? "ml_agent" : "ml-${replace(lower(var.instance_key), "_", "-")}-agent"

  service_connect_port_name = local.agent_container_name

  service_discovery_namespace_name = local.legacy ? "ml_agent" : "${local.ml_prefix}-agent-sc"

  agent_target_group_name = local.legacy ? "generic-private-ml-tg-agent" : substr(
    replace("${local.ml_prefix}-pvt-tg", "_", "-"),
    0,
    32
  )

  iam_log_policy_name  = local.legacy ? "ml_ecs_agent_logs" : replace("${local.ml_prefix}_ecs_agent_logs", "-", "_")
  iam_s3_policy_name   = local.legacy ? "ml_ecs_agent_s3_access" : replace("${local.ml_prefix}_ecs_agent_s3_access", "-", "_")
  cloudwatch_dashboard = local.legacy ? "neuroagent" : substr("neuroagent-${replace(lower(var.instance_key), "_", "-")}", 0, 255)

  ml_subnet_a_tag_name = local.legacy ? "ml_a" : "${local.ml_prefix}_subnet_a"
  ml_subnet_b_tag_name = local.legacy ? "ml_b" : "${local.ml_prefix}_subnet_b"
}
