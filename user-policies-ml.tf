variable "ml_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:ml_secrets-uEWnHv"
  type        = string
  description = "The ARN of the Machine Learning secrets object"
  sensitive   = false
}

variable "ml_rds_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:rds!db-919c6599-92eb-4097-9514-ccadb9ce403e-H29aEv"
  type        = string
  description = "The ARN of the Machine Learning RDS DB secrets object"
  sensitive   = false
}

resource "aws_ssoadmin_permission_set" "write_read_access_ml_secrets" {
  name             = "WriteReadMlSecrets"
  description      = "Write and Read access for ML secrets"
  instance_arn     = tolist(data.aws_ssoadmin_instances.ssoadmin_instances.arns)[0]
  session_duration = "PT2H"
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "write_read_access_ml_secrets_inline_policy" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.write_read_access_ml_secrets_policy),
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
    ]
  })
  instance_arn       = tolist(data.aws_ssoadmin_instances.ssoadmin_instances.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.write_read_access_ml_secrets.arn
}

locals {
  write_read_access_ml_secrets_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ],
    "Resource" : [
      "${var.ml_secrets_arn}",
      "${var.ml_rds_secrets_arn}",
    ]
  })
}
