resource "aws_iam_role" "nexus_delta_ecs_task" {
  name = "${var.delta_instance_name}-ecsTaskRole"

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
}

resource "aws_iam_role_policy_attachment" "delta_ecs_task" {
  role       = aws_iam_role.nexus_delta_ecs_task.name
  policy_arn = aws_iam_policy.nexus_delta_s3_bucket_access.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "nexus_delta_s3_bucket_access" {
  name        = "${var.delta_instance_name}-NexusDeltaBucketAccess"
  description = "A policy that grants access to the delta S3 bucket"

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
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
      },
    ]
  })

  tags = {
    SBO_Billing = "nexus"
    Nexus       = "delta"
  }
}
