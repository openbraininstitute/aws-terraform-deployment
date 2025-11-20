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
