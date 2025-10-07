# Define the policy to access S3
resource "aws_iam_policy" "s3_access" {
  name        = "obi_one_v2_s3_access_policy"
  description = "Policy that gives readonly access to S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for cfg in var.mount_buckets : {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${cfg.bucket_name}",
          "arn:aws:s3:::${cfg.bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.obi_one_v2_ec2_instance_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}
