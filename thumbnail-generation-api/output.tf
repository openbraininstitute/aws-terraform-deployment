output "private_lb_rule_suffix" {
  description = "Thumbnail Generator Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.main.arn_suffix
}
