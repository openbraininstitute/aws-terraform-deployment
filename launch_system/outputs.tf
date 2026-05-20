output "private_lb_rule_suffix" {
  description = "Launch System Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private.arn_suffix
}

output "executor_network_ids" {
  description = "Subnet ids where the Launch System Executor is deployed"
  value = [
    aws_subnet.untrusted_a.id,
    aws_subnet.untrusted_b.id,
  ]
}

output "executor_subnet_cidr_blocks" {
  description = "CIDR blocks of the launch_system executor (untrusted) subnets"
  value = [
    aws_subnet.untrusted_a.cidr_block,
    aws_subnet.untrusted_b.cidr_block,
  ]
}

output "orchestrator_subnet_cidr_blocks" {
  description = "CIDR blocks of the launch_system orchestrator (trusted) subnets"
  value = [
    aws_subnet.trusted_a.cidr_block,
    aws_subnet.trusted_b.cidr_block,
  ]
}

output "pcs_subnet_cidr_block" {
  description = "CIDR block of the PCS subnet"
  value       = aws_subnet.pcs.cidr_block
}

output "rds_db_identifier" {
  value = aws_db_instance.main.identifier
}
