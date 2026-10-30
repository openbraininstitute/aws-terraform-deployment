# --- AgentCore Memory (separate execution role from the Runtime role) ---

data "aws_iam_policy_document" "research_agent_memory_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "research_agent_memory" {
  name               = "research_agent_memory"
  assume_role_policy = data.aws_iam_policy_document.research_agent_memory_trust.json
}

resource "aws_bedrockagentcore_memory" "research_agent" {
  name                      = "research_agent"
  memory_execution_role_arn = aws_iam_role.research_agent_memory.arn
  event_expiry_duration     = var.event_expiry_duration
}

# Long-term strategy: a running summary per session, auto-extracted by
# AWS from conversation events. A separate Terraform resource, not a
# nested block on aws_bedrockagentcore_memory (confirmed via the
# installed provider's own schema).
resource "aws_bedrockagentcore_memory_strategy" "research_agent_summarization" {
  memory_id           = aws_bedrockagentcore_memory.research_agent.id
  name                = "SessionSummarizer"
  type                = "SUMMARIZATION"
  namespace_templates = ["/summaries/{actorId}/{sessionId}/"]
}

# --- Grant the Runtime execution role access to this Memory resource ---

data "aws_iam_policy_document" "research_agent_runtime_memory_permissions" {
  statement {
    sid = "MemoryEvents"
    actions = [
      "bedrock-agentcore:CreateEvent",
      "bedrock-agentcore:ListEvents",
      "bedrock-agentcore:GetEvent",
      "bedrock-agentcore:ListSessions",
    ]
    resources = [aws_bedrockagentcore_memory.research_agent.arn]
  }
}

resource "aws_iam_role_policy" "research_agent_runtime_memory_permissions" {
  name   = "memory-access"
  role   = aws_iam_role.research_agent_runtime.id
  policy = data.aws_iam_policy_document.research_agent_runtime_memory_permissions.json
}
