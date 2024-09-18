output "lb_rule_suffix" {
  description = "Core Web app Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.core_webapp.arn_suffix
}
