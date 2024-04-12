#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "s3_read_access" {
  name        = "S3ShipBucketReadAccess"
  description = "A policy that grants read-only access to the ship S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.nexus_ship.arn
      },
    ]
  })
}