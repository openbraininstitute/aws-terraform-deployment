resource "aws_iam_role" "nexus_delta_ecs_task" {
  name = "nexus_delta-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
  tags = {
    SBO_Billing = "nexus_ship"
  }
}

resource "aws_iam_role_policy_attachment" "ship_ecs_task" {
  role       = aws_iam_role.nexus_delta_ecs_task.name
  policy_arn = aws_iam_policy.nexus_delta_bucket_access.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "nexus_delta_bucket_access" {
  name        = "NexusDeltaBucketAccess"
  description = "A policy that grants read-only access to the ship S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Put*",
          "s3:Copy*"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.nexus_delta.arn
      },
    ]
  })
}

