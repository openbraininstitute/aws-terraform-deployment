variable "nexus_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:nexus*"
  type        = string
  description = "The ARN of all nexus* secrets objects"
  sensitive   = false
}

resource "aws_ssoadmin_permission_set" "write_read_access_nexus_secrets" {
  name             = "WriteReadNexusSecrets"
  description      = "Write and Read access for Nexus secrets"
  instance_arn     = tolist(data.aws_ssoadmin_instances.ssoadmin_instances.arns)[0]
  session_duration = "PT2H"
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "write_read_access_nexus_secrets_inline_policy" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.write_read_access_nexus_secrets_policy),
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
    ]
  })
  instance_arn       = tolist(data.aws_ssoadmin_instances.ssoadmin_instances.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.write_read_access_nexus_secrets.arn
}

locals {
  write_read_access_nexus_secrets_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ],
    "Resource" : [
      "${var.nexus_secrets_arn}",
    ]
  })
}
