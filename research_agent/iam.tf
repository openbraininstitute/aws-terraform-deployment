# --- Runtime execution role ---

data "aws_iam_policy_document" "research_agent_runtime_trust" {
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

resource "aws_iam_role" "research_agent_runtime" {
  name               = "research_agent_runtime"
  assume_role_policy = data.aws_iam_policy_document.research_agent_runtime_trust.json
}

data "aws_iam_policy_document" "research_agent_runtime_permissions" {
  statement {
    sid       = "BedrockModelInvoke"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["*"] # tightened once the specific model ARN is fixed
  }

  # Observability (OTEL spans/metrics) - a real, separate IAM
  # requirement per AWS's own documented execution-role policy, not
  # something Runtime grants for free. Without this, the ADOT exporter
  # gets a 403 on every export attempt regardless of in-code OTEL setup.
  statement {
    sid = "ObservabilityLogs"
    actions = [
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"]
  }

  statement {
    sid       = "ObservabilityLogsResourcePolicy"
    actions   = ["logs:PutResourcePolicy"]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/research_agent-*"]
  }

  statement {
    sid       = "ObservabilityLogsDescribe"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }

  statement {
    sid = "ObservabilityLogsPut"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"]
  }

  statement {
    sid = "ObservabilityXray"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ObservabilityMetrics"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["bedrock-agentcore"]
    }
  }

  # Pulling the agent container from the cross-account research-agent
  # ECR repo (985539765147, see openbraininstitute/aws-terraform-ecr
  # PR #116 for the matching repo-policy grant on the other side).
  # GetAuthorizationToken doesn't support resource-level restriction -
  # AWS's own managed ECR policies also use Resource: "*" for it.
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPullResearchAgent"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:985539765147:repository/research-agent"]
  }
}

resource "aws_iam_role_policy" "research_agent_runtime_permissions" {
  name   = "runtime-permissions"
  role   = aws_iam_role.research_agent_runtime.id
  policy = data.aws_iam_policy_document.research_agent_runtime_permissions.json
}
