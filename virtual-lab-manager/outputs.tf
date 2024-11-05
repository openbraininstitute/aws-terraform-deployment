output "private_arn_suffix" {
  description = "Virtuallab Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.virtual_lab_manager_private.arn_suffix
}
