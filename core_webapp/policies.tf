data "aws_caller_identity" "current" {}

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
