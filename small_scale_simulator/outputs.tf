output "private_lb_rule_suffix" {
  description = "Small Scale Simulator loadbalancer rule suffix"
  value       = aws_lb_target_group.main.arn_suffix
}

output "subnet_cidr_blocks" {
  description = "CIDR blocks of the small_scale_simulator subnets"
  value = [
    aws_subnet.small_scale_simulator_primary_a.cidr_block,
    aws_subnet.small_scale_simulator_primary_b.cidr_block,
    aws_subnet.small_scale_simulator_secondary_a.cidr_block,
    aws_subnet.small_scale_simulator_secondary_b.cidr_block,
  ]
}
