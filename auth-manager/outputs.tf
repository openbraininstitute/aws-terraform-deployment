output "private_lb_rule_suffix" {
  description = "auth manager Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.auth_manager_private_tg.arn_suffix
}
