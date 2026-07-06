resource "aws_iam_policy" "secrets_access" {
  name        = "entitycore-service-secrets-access-policy"
  description = "Policy that gives access to the entitycore service secrets"

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
          "${var.entitycore_service_secrets_arn}"
        ]
      }
    ]
  }
  EOT
}

resource "aws_iam_policy" "s3_access" {
  name        = "entitycore-service-s3-access-policy"
  description = "Policy that gives access to the entitycore service S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.aws_s3_internal_bucket}",
          "arn:aws:s3:::${var.aws_s3_internal_bucket}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the task role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ecs_entitycore_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role" "rds_enhanced_monitoring_entitycore" {
  name = "rds-enhanced-monitoring-entitycore"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "monitoring.rds.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_entitycore" {
  role       = aws_iam_role.rds_enhanced_monitoring_entitycore.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
