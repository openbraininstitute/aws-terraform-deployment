locals {
  ecs_cluster_arn    = module.ml_ecs_cluster.arn
  private_subnet_ids = [aws_subnet.ml_subnet_a.id, aws_subnet.ml_subnet_b.id]

  # Short stack slug for names (empty = original single-stack naming).
  ml_prefix = var.instance_key == "" ? "ml" : "ml-${var.instance_key}"

  ecs_cluster_name = "${local.ml_prefix}-ecs-cluster"

  rds_security_group_name = "${local.ml_prefix}-rds"
  rds_instance_identifier = "${local.ml_prefix}-rds-postgres"

  redis_security_group_name = "${local.ml_prefix}-redis-sg"
  redis_subnet_group_name   = "${local.ml_prefix}-redis-subnet-group"

  # ElastiCache cluster_id max 20 characters.
  elasticache_cluster_id = var.instance_key == "" ? var.ec_cluster_name : substr(
    "redis-${replace(lower(var.instance_key), "_", "-")}",
    0,
    20
  )

  ecs_service_name = "${local.ml_prefix}-ecs-svc-agent"

  # Single container / Service Connect / TG naming.
  agent_container_name = var.instance_key == "" ? "ml_agent" : "ml-${replace(lower(var.instance_key), "_", "-")}-agent"

  # Service Connect port_name: [a-zA-Z0-9][a-zA-Z0-9-]* — align with container name (hyphens ok).
  service_connect_port_name = local.agent_container_name

  service_discovery_namespace_name = "${local.ml_prefix}-agent-sc"

  # ALB target group name max 32.
  agent_target_group_name = substr(replace("${local.ml_prefix}-pvt-tg", "_", "-"), 0, 32)

  # IAM policy names: allow A-Za-z0-9_+=,.@-- characters; avoid hyphens for simplicity.
  iam_log_policy_name  = replace("${local.ml_prefix}_ecs_agent_logs", "-", "_")
  iam_s3_policy_name   = replace("${local.ml_prefix}_ecs_agent_s3_access", "-", "_")
  cloudwatch_dashboard = var.instance_key == "" ? "neuroagent" : substr("neuroagent-${replace(lower(var.instance_key), "_", "-")}", 0, 255)
}
