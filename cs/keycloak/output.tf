output "private_keycloak_lb_rule_suffix" {
  description = "Keycloak Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_keycloak_target_group.arn_suffix
}

output "ecs_cluster_name" {
  value = var.keycloak_ecs_cluster_name
}

output "ecs_service_name" {
  value = var.keycloak_ecs_service_name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.sbo_keycloak_task.family
}

output "rds_db_identifier" {
  value = aws_db_instance.keycloak_database.identifier
}
