output "private_lb_rule_suffix" {
  description = "Service Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_tg.arn_suffix
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.ecs_definition.family
}

output "ecs_container_names" {
  value = local.container_names
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.ecs_task_logs.name
}

output "ecs_cidr_block_a" {
  value = var.ecs_cidr_block_a
}

output "ecs_cidr_block_b" {
  value = var.ecs_cidr_block_b
}

output "subnet_cidr_blocks" {
  description = "CIDR blocks of the notebook_service subnets"
  value       = [var.ecs_cidr_block_a, var.ecs_cidr_block_b]
}
