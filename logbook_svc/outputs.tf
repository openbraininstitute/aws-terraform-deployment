output "alarms_sns_topic_arn" {
  description = "SNS topic of the logbook alarms (alarms.tf); monitoring.tf sends it to Teams and to a debug queue"
  value       = aws_sns_topic.logbook_alarms.arn
}

output "private_lb_rule_suffix" {
  description = "logbook Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.logbook_private_tg.arn_suffix
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.logbook_ecs_task_logs.name
}

output "rds_db_identifier" {
  value = aws_db_instance.logbook.identifier
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.logbook.name
}

output "ecs_service_name" {
  value = aws_ecs_service.logbook_ecs_service.name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.logbook_ecs_definition.family
}

output "ecs_container_names" {
  value = [local.container_name]
}

output "subnet_cidr_blocks" {
  description = "CIDR blocks of the logbook task subnets (for allow-lists of other services)"
  value       = [var.ecs_cidr_block_a, var.ecs_cidr_block_b]
}
