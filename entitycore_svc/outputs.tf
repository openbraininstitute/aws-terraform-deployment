output "private_lb_rule_suffix" {
  description = "entitycore Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.entitycore_private_tg.arn_suffix
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.entitycore_ecs_task_logs.name
}
