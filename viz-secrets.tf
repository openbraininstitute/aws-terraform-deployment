# Created in AWS secret manager
variable "viz_vsm_db_password_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:viz_vsm_db_password-HpmfWe"
  type        = string
  description = "The ARN of the viz vsm secret"
  sensitive   = true
}

resource "aws_ssoadmin_permission_set" "write_read_access_viz_secrets" {
  name             = "WriteReadVizVsmSecrets"
  description      = "Write and Read access for Viz VSM secrets"
  instance_arn     = var.aws_iam_identity_center_arn
  session_duration = "PT2H"
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "write_read_access_viz_secrets_inline_policy" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.write_read_access_viz_secrets_policy),
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
    ]
  })
  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.write_read_access_viz_secrets.arn
}

locals {
  write_read_access_viz_secrets_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ],
    "Resource" : [
      "${var.viz_vsm_db_password_arn}"
    ]
  })
}
