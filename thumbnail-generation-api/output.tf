output "private_lb_rule_suffix" {
  description = "Thumbnail Generator Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_tg.arn_suffix
}
