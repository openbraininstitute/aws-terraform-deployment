output "subnet_cidr_blocks" {
  value = [var.subnet_cidr_block_a, var.subnet_cidr_block_b]
}

output "runtime_role_arn" {
  value = aws_iam_role.research_agent_runtime.arn
}

output "agent_runtime_arn" {
  value = aws_bedrockagentcore_agent_runtime.research_agent.agent_runtime_arn
}

output "memory_id" {
  value = aws_bedrockagentcore_memory.research_agent.id
}
