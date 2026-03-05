# IAM User for SES
resource "aws_iam_user" "ses_user" {
  name = var.user_name
}

# IAM Inline Policy Attached to User
resource "aws_iam_user_policy" "ses_inline_policy" {
  name = "AmazonSesSendingAccess"
  user = aws_iam_user.ses_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

# IAM role for the rotation Lambda
resource "aws_iam_role" "ses_rotation_lambda" {
  name = "ses-credentials-rotation-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ses_rotation_lambda" {
  role = aws_iam_role.ses_rotation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys"
        ]
        Resource = aws_iam_user.ses_user.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = var.secret_arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Rotation Lambda code
data "archive_file" "rotation_lambda" {
  type        = "zip"
  output_path = "${path.module}/rotation_lambda.zip"

  source {
    content  = <<-PYTHON
import boto3
import hmac
import hashlib
import base64
import json

def handler(event, context):
    secret_id = event['SecretId']
    token      = event['ClientRequestToken']
    step       = event['Step']

    sm  = boto3.client('secretsmanager')
    iam = boto3.client('iam')

    meta = sm.describe_secret(SecretId=secret_id)
    if not meta.get('RotationEnabled'):
        raise ValueError("Rotation not enabled")
    if token not in meta['VersionIdsToStages']:
        raise ValueError("Token not found in secret versions")

    if step == 'createSecret':
        # Skip if AWSPENDING already exists (idempotency)
        if 'AWSPENDING' in meta['VersionIdsToStages'].get(token, []):
            return

        current = json.loads(sm.get_secret_value(SecretId=secret_id, VersionStage='AWSCURRENT')['SecretString'])
        new_key = iam.create_access_key(UserName='${var.user_name}')['AccessKey']
        smtp_password = _compute_smtp_password(new_key['SecretAccessKey'], '${var.aws_region}')
        new_secret = dict(current)
        new_secret['mail_username'] = new_key['AccessKeyId']
        new_secret['mail_password'] = smtp_password
        sm.put_secret_value(SecretId=secret_id, ClientRequestToken=token,
                            SecretString=json.dumps(new_secret), VersionStages=['AWSPENDING'])

    elif step == 'setSecret':
        pass

    elif step == 'testSecret':
        pending = json.loads(sm.get_secret_value(SecretId=secret_id, VersionStage='AWSPENDING')['SecretString'])
        if not pending.get('mail_username') or not pending.get('mail_password'):
            raise ValueError("Pending secret missing credentials")

    elif step == 'finishSecret':
        # Get old key ID before promoting
        current_version_id = meta['VersionIdsToStages']['AWSCURRENT'][0]
        current = json.loads(sm.get_secret_value(SecretId=secret_id, VersionStage='AWSCURRENT')['SecretString'])
        old_key_id = current.get('mail_username')

        # Promote AWSPENDING to AWSCURRENT
        sm.update_secret_version_stage(
            SecretId=secret_id,
            VersionStage='AWSCURRENT',
            MoveToVersionId=token,
            RemoveFromVersionId=current_version_id
        )

        # Delete old IAM access key
        if old_key_id:
            try:
                iam.delete_access_key(UserName='${var.user_name}', AccessKeyId=old_key_id)
            except iam.exceptions.NoSuchEntityException:
                pass

def _compute_smtp_password(secret_key, region):
    date     = b'11111111'
    service  = b'ses'
    message  = b'SendRawEmail'
    terminal = b'aws4_request'
    k_date    = hmac.new(b'AWS4' + secret_key.encode(), date,           hashlib.sha256).digest()
    k_region  = hmac.new(k_date,                        region.encode(), hashlib.sha256).digest()
    k_service = hmac.new(k_region,                      service,         hashlib.sha256).digest()
    k_signing = hmac.new(k_service,                     terminal,        hashlib.sha256).digest()
    signature = hmac.new(k_signing,                     message,         hashlib.sha256).digest()
    return base64.b64encode(b'\x04' + signature).decode()
PYTHON
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "ses_rotation" {
  filename         = data.archive_file.rotation_lambda.output_path
  function_name    = "ses-credentials-rotation"
  role             = aws_iam_role.ses_rotation_lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256
  timeout          = 30
}

resource "aws_lambda_permission" "secrets_manager" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ses_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = var.secret_arn
}

resource "aws_secretsmanager_secret_rotation" "ses_credentials" {
  secret_id           = var.secret_arn
  rotation_lambda_arn = aws_lambda_function.ses_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}
