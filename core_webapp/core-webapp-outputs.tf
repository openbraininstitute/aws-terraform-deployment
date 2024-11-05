output "private_lb_rule_suffix" {
  description = "Core Web app Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.core_webapp_private.arn_suffix
}
