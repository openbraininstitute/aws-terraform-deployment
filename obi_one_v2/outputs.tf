output "private_lb_rule_suffix" {
  description = "Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_obi_one_v2.arn_suffix
}

output "subnet_cidr_blocks" {
  description = "CIDR blocks of the obi_one_v2 subnets"
  value       = [aws_subnet.obi_one_v2.cidr_block]
}
