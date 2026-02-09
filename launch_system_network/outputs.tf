output "executor_network_ids" {
  description = "Subnet ids where the Launch System Executor is deployed"
  value = [
    aws_subnet.untrusted_a.id,
    aws_subnet.untrusted_b.id,
  ]
}

output "trusted_a_subnet_id" {
  description = "ID of the trusted_a subnet where the trusted systems are deployed"
  value       = aws_subnet.trusted_a.id
}

output "trusted_b_subnet_id" {
  description = "ID of the trusted_b subnet where the trusted systems are deployed"
  value       = aws_subnet.trusted_b.id
}

output "untrusted_a_subnet_id" {
  description = "ID of the untrusted_a subnet where the untrusted systems are deployed"
  value       = aws_subnet.untrusted_a.id
}

output "untrusted_b_subnet_id" {
  description = "ID of the untrusted_b subnet where the untrusted systems are deployed"
  value       = aws_subnet.untrusted_b.id
}
