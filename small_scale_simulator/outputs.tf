output "private_lb_rule_suffix" {
  description = "Small Scale Simulator Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.main.arn_suffix
}
