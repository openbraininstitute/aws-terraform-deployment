data "aws_caller_identity" "current" {}

locals {
  github_actions_ci_upload_user_name = "github_actions_upload_user_core_web_app"
}


resource "aws_iam_policy" "core_webapp_s3_cloudfront_access" {
  count = var.ecs_number_of_containers > 0 ? 1 : 0

  name        = "core-webapp-${var.key}-s3-cloudfront-access-policy"
  description = "Policy that gives CloudFront access to the core webapp S3 bucket for assets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.core_webapp.arn,
          "${aws_s3_bucket.core_webapp.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.core_webapp_cdn.id}"
          }
        }
      }
    ]
  })

  tags = {
    SBO_Billing = "core_webapp"
  }
}

# IAM policy for GitHub Actions to upload files to S3 bucket
resource "aws_iam_policy" "core_webapp_s3_upload_policy" {
  name        = "core-webapp-${var.key}-s3-upload-policy"
  description = "Policy that allows GitHub Actions to upload files to the core webapp S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListObjectsInBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.core_webapp.arn
        ]
      },
      {
        Sid    = "AllObjectActions"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.core_webapp.arn}/*"
        ]
      }
    ]
  })

  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_iam_user_policy_attachment" "github_actions_s3_upload" {
  count      = 1
  user       = local.github_actions_ci_upload_user_name
  policy_arn = aws_iam_policy.core_webapp_s3_upload_policy.arn
}
