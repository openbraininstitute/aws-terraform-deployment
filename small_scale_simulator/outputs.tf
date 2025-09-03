output "private_lb_rule_suffix" {
  description = "Small Scale Simulator loadbalancer rule suffix"
  value       = aws_lb_target_group.main.arn_suffix
}
