output "private_lb_rule_suffix" {
  description = "obi-one Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.obi_one_private_tg.arn_suffix
}
