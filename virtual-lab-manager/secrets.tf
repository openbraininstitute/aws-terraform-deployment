# Created in AWS secret manager
# TODO: replace the ARN below with a real value.
# The secret is expected to have the following keys:
# - keycloak_admin_username
# - keycloak_admin_password
# - database_password
# - invite_jwt_secret
# - mail_password
# - mail_username
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

  tags = var.virtual_lab_manager_tags
}

# Force ECS redeploy when SES credentials are rotated
data "archive_file" "redeploy_lambda" {
  type        = "zip"
  output_path = "${path.module}/redeploy_lambda.zip"

  source {
    content  = <<-PYTHON
import boto3
import os

def handler(event, context):
    ecs = boto3.client('ecs')
    ecs.update_service(
        cluster=os.environ['ECS_CLUSTER'],
        service=os.environ['ECS_SERVICE'],
        forceNewDeployment=True
    )
PYTHON
    filename = "lambda_function.py"
  }
}

resource "aws_iam_role" "redeploy_lambda" {
  name = "vlm-ses-rotation-redeploy-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "redeploy_lambda" {
  role = aws_iam_role.redeploy_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecs:UpdateService"
        Resource = "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/virtual_lab_manager_ecs_cluster/virtual_lab_manager_ecs_service"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "redeploy" {
  filename         = data.archive_file.redeploy_lambda.output_path
  function_name    = "vlm-ses-rotation-redeploy"
  role             = aws_iam_role.redeploy_lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.redeploy_lambda.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      ECS_CLUSTER = "virtual_lab_manager_ecs_cluster"
      ECS_SERVICE = "virtual_lab_manager_ecs_service"
    }
  }
}

resource "aws_cloudwatch_event_rule" "ses_secret_rotation" {
  name = "vlm-ses-secret-rotation-redeploy"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName   = ["RotationSucceeded"]
      requestParameters = {
        secretId = [var.virtual_lab_manager_secrets_arn]
      }
    }
  })
}

resource "aws_lambda_permission" "eventbridge_redeploy" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redeploy.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ses_secret_rotation.arn
}

resource "aws_cloudwatch_event_target" "ses_secret_rotation" {
  rule = aws_cloudwatch_event_rule.ses_secret_rotation.name
  arn  = aws_lambda_function.redeploy.arn
}