variable "ml_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:ml_secrets-uEWnHv"
  type        = string
  description = "The ARN of the Machine Learning secrets object"
  sensitive   = true
}

variable "ml_mwaa_arn" {
  default     = "arn:aws:airflow:us-east-1:671250183987:environment/ml-airflow"
  type        = string
  description = "The ARN of the Machine Learning MWAA object"
  sensitive   = true
}

resource "aws_ssoadmin_permission_set" "write_read_access_ml_secrets" {
  name             = "WriteReadMlSecrets"
  description      = "Write and Read access for ML secrets"
  instance_arn     = var.aws_iam_identity_center_arn
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
  instance_arn       = var.aws_iam_identity_center_arn
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
      "${var.ml_secrets_arn}"
    ]
  })
}

resource "aws_ssoadmin_permission_set" "write_read_access_ml_mwaa" {
  name             = "MWAAfullAccessML"
  description      = "Write and Read access for ML MWAA"
  instance_arn     = var.aws_iam_identity_center_arn
  session_duration = "PT2H"
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "write_read_access_ml_mwaa_inline_policy" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.ml_mwaa_list_env_policy),
      jsondecode(local.ml_mwaa_full_access_policy),
      jsondecode(local.ml_mwaa_web_access_policy),
    ]
  })
  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.write_read_access_ml_mwaa.arn
}

locals {
  ml_mwaa_web_access_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "airflow:CreateWebLoginToken",
    ]
    Resource = "*"
  })

  ml_mwaa_list_env_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "airflow:ListEnvironments",
    ]
    Resource = "*"
  })

  ml_mwaa_full_access_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "airflow:*",
    ]
    "Resource" : [
      "${var.ml_mwaa_arn}"
    ]
  })
}
