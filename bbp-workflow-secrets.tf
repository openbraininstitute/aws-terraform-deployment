# Created in AWS secret manager
variable "bbp_workflow_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:bbp-workflow-V8k6ff"
  type        = string
  description = "The ARN of the BBP workflow secrets"
  sensitive   = true
}

resource "aws_iam_policy" "bbp_workflow_secrets_access" {
  name        = "bbp-workflow-secrets-access-policy"
  description = "Policy that gives access to the bbp-workflow secrets"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${var.bbp_workflow_secrets_arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_ssoadmin_permission_set" "write_read_access_workflow_secrets" {
  name             = "WriteReadAccessWorkflowSecrets"
  description      = "Write and Read access for Workflow secrets"
  instance_arn     = var.aws_iam_identity_center_arn
  session_duration = "PT2H"
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "write_read_access_workflow_secrets_inline_policy" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.write_read_access_workflow_secrets_policy),
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
    ]
  })
  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.write_read_access_workflow_secrets.arn
}

locals {
  write_read_access_workflow_secrets_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:CreateSecret",
      "secretsmanager:UpdateSecret"
    ],
    "Resource" : [
      "${var.bbp_workflow_secrets_arn}"
    ]
  })
}
