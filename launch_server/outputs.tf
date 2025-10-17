output "private_lb_rule_suffix" {
  description = "Launch Server Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.launch_private_tg.arn_suffix
}
