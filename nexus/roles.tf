resource "aws_iam_role" "nexus_ecs_task_execution" {
  name = "nexus-ecsTaskExecutionRole"

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
    SBO_Billing = "nexus"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_service" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "dockerhub_secret_access" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = var.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "nexus_secret_access" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = aws_iam_policy.nexus_secrets_access.arn
}