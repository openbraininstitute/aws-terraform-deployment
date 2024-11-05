output "private_lb_rule_suffix" {
  description = "Cell service Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_cell_svc.arn_suffix
}
