#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "ship_import_bucket_access" {
  name        = "S3ShipBucketAccess"
  description = "A policy that grants read-only access to the ship S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Copy*",
          "s3:Put*"
        ]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.nexus_ship.arn, "${aws_s3_bucket.nexus_ship.arn}/*"]
      },
    ]
  })
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "ship_target_bucket_access" {
  name        = "NexusShipTargetBucketAccess"
  description = "A policy that grants read-only access to the ship S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Copy*",
          "s3:Put*"
        ]
        Effect   = "Allow"
        Resource = [var.target_bucket_arn, "${var.target_bucket_arn}/*"]
      },
    ]
  })
}
