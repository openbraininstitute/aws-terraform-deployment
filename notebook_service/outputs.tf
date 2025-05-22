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
