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
