output "private_arn_suffix" {
  description = "Virtuallab Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.virtual_lab_manager_private.arn_suffix
}

output "subnet_cidr_blocks" {
  description = "CIDR blocks of the virtual_lab_manager subnets"
  value = [
    aws_subnet.virtual_lab_manager_a.cidr_block,
    aws_subnet.virtual_lab_manager_b.cidr_block,
  ]
}
