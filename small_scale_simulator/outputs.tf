output "private_lb_rule_suffix" {
  description = "Small Scale Simulator Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.main.arn_suffix
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "api_ecs_service_name" {
  value = aws_ecs_service.api.name
}

output "api_ecs_task_definition_name" {
  value = aws_ecs_task_definition.api.family
}

output "worker_ecs_service_name" {
  value = aws_ecs_service.worker.name
}

output "worker_ecs_task_definition_name" {
  value = aws_ecs_task_definition.worker.family
}
