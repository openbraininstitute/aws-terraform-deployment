output "ecs_cluster_name" {
  value = aws_ecs_cluster.core_webapp.name
}

output "ecs_service_name" {
  value = aws_ecs_service.core_webapp_ecs_service[0].name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.core_webapp_ecs_definition[0].family
}
