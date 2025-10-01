output "private_lb_rule_suffix" {
  description = "Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_obi_one_v2.arn_suffix
}
