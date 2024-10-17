# Created in AWS secret manager
# TODO: replace the ARN below with a real value.
# The secret is expected to have the following keys:
# - keycloak_admin_username
# - keycloak_admin_password
# - database_password
# - invite_jwt_secret
# - mail_password
resource "aws_iam_policy" "virtual_lab_manager_secrets_access" {
  name        = "virtual-lab-manager-secrets-access-policy"
  description = "Policy that gives access to the virtual lab manager secrets"

  policy = <<-EOT
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
          "${var.virtual_lab_manager_secrets_arn}"
        ]
      }
    ]
  }
  EOT

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}
