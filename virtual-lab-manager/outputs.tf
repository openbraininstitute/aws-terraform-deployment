output "arn_suffix" {
  description = "Virtuallab Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.virtual_lab_manager.arn_suffix
}
