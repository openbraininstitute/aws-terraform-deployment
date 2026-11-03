resource "aws_bedrockagentcore_agent_runtime" "research_agent" {
  agent_runtime_name = "research_agent"
  role_arn           = aws_iam_role.research_agent_runtime.arn
  description        = "Autonomous research agent - ask_research over notebook-service/JupyterHub"

  agent_runtime_artifact {
    container_configuration {
      container_uri = var.container_uri
    }
  }

  network_configuration {
    network_mode = "VPC"

    network_mode_config {
      subnets = [
        aws_subnet.research_agent_a.id,
        aws_subnet.research_agent_b.id,
      ]
      security_groups = [aws_security_group.research_agent_runtime.id]
    }
  }

  environment_variables = {
    NOTEBOOK_SERVICE_URL    = var.notebook_service_url
    AGENT_MAX_TURNS         = tostring(var.agent_max_turns)
    AGENT_MAX_OUTPUT_TOKENS = tostring(var.agent_max_output_tokens)
    AGENT_MAX_TOTAL_TOKENS  = tostring(var.agent_max_total_tokens)
    AGENT_MAX_TOOL_CALLS    = tostring(var.agent_max_tool_calls)
    MEMORY_ID               = aws_bedrockagentcore_memory.research_agent.id
    ACCOUNTING_BASE_URL     = var.accounting_base_url
    ACCOUNTING_DISABLED     = var.accounting_disabled ? "1" : "0"
  }

  tags = {
    Name = "research-agent"
  }
}
