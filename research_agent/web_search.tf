# --- AgentCore Gateway: Web Search Tool connector (prod-ai#140) ---
#
# AWS's own docs confirm this connector is framework/model-agnostic
# ("Works with Strands Agents, LangChain, LangGraph, CrewAI, or any
# MCP-compatible client") - unlike plain Bedrock Web Search, which is
# OpenAI-gated. AWS_IAM authorizer (SigV4), not CUSTOM_JWT/Cognito:
# this Runtime calls its own Gateway within the same account, not a
# user-facing OAuth flow.

# The Gateway's own service role - distinct from the Runtime execution
# role below. This is what AgentCore assumes to actually invoke the
# Web Search backend on the Gateway's behalf.
data "aws_iam_policy_document" "research_agent_web_search_gateway_trust" {
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

resource "aws_iam_role" "research_agent_web_search_gateway" {
  name               = "research_agent_web_search_gateway"
  assume_role_policy = data.aws_iam_policy_document.research_agent_web_search_gateway_trust.json
}

data "aws_iam_policy_document" "research_agent_web_search_gateway_permissions" {
  statement {
    sid       = "InvokeGateway"
    actions   = ["bedrock-agentcore:InvokeGateway"]
    resources = ["arn:aws:bedrock-agentcore:${var.aws_region}:${data.aws_caller_identity.current.account_id}:gateway/*"]
  }

  statement {
    sid       = "InvokeWebSearch"
    actions   = ["bedrock-agentcore:InvokeWebSearch"]
    resources = ["arn:aws:bedrock-agentcore:${var.aws_region}:aws:tool/web-search.v1"]
  }
}

resource "aws_iam_role_policy" "research_agent_web_search_gateway_permissions" {
  name   = "web-search-gateway-permissions"
  role   = aws_iam_role.research_agent_web_search_gateway.id
  policy = data.aws_iam_policy_document.research_agent_web_search_gateway_permissions.json
}

resource "aws_bedrockagentcore_gateway" "research_agent_web_search" {
  name            = "research-agent-web-search"
  role_arn        = aws_iam_role.research_agent_web_search_gateway.arn
  authorizer_type = "AWS_IAM"

  protocol_configuration {
    mcp {
      instructions = "Search the web for current, cited information to ground research_agent's responses."
    }
  }
}

resource "aws_bedrockagentcore_gateway_target" "web_search" {
  gateway_identifier = aws_bedrockagentcore_gateway.research_agent_web_search.gateway_id
  name               = "web-search"

  target_configuration {
    mcp {
      connector {
        source {
          connector_id = "web-search"
        }

        # "WebSearch" is the connector's own fixed tool name, not an
        # arbitrary choice - confirmed against AWS's own target
        # configuration guide and a published CDK sample.
        configuration {
          name             = "WebSearch"
          parameter_values = "{}"
        }
      }
    }
  }

  credential_provider_configuration {
    gateway_iam_role {}
  }
}

# --- Grant the Runtime execution role permission to call this Gateway ---
# (Separate from the Gateway's own service role above - this is our
# side, the caller, not the Gateway itself.)

data "aws_iam_policy_document" "research_agent_runtime_web_search_permissions" {
  statement {
    sid       = "InvokeWebSearchGateway"
    actions   = ["bedrock-agentcore:InvokeGateway"]
    resources = [aws_bedrockagentcore_gateway.research_agent_web_search.gateway_arn]
  }
}

resource "aws_iam_role_policy" "research_agent_runtime_web_search_permissions" {
  name   = "web-search-gateway-access"
  role   = aws_iam_role.research_agent_runtime.id
  policy = data.aws_iam_policy_document.research_agent_runtime_web_search_permissions.json
}
