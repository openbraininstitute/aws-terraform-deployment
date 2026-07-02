output "private_lb_rule_suffix" {
  description = "Grading service load balancer rule suffix"
  value       = aws_lb_target_group.main.arn_suffix
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.api.family
}
