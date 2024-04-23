resource "aws_iam_role" "nexus_ship_ecs_task" {
  name = "nexus_ship-ecsTaskRole"

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

resource "aws_iam_role_policy_attachment" "import_bucket_access" {
  role       = aws_iam_role.nexus_ship_ecs_task.name
  policy_arn = aws_iam_policy.ship_import_bucket_access.arn
}

resource "aws_iam_role_policy_attachment" "target_bucket_access" {
  role       = aws_iam_role.nexus_ship_ecs_task.name
  policy_arn = aws_iam_policy.ship_target_bucket_access.arn
}