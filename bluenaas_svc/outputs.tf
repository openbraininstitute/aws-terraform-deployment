output "private_lb_rule_suffix" {
  description = "BlueNaaS service Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.bluenaas_private_tg.arn_suffix
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.bluenaas.name
}

output "ecs_service_name" {
  value = aws_ecs_service.bluenaas_ecs_service.name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.bluenaas_ecs_definition.family
}
