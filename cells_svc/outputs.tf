output "lb_rule_suffix" {
  description = "Cell service Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.cell_svc.arn_suffix
}
