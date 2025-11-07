output "private_lb_rule_suffix" {
  description = "Launch System Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private.arn_suffix
}
