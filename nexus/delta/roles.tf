resource "aws_iam_role" "ecs_nexus_app_task_execution_role" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_app-ecsTaskExecutionRole"

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
    SBO_Billing = "nexus_app"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_app_task_execution_role_policy_attachment" {
  count      = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_app_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_nexus_app_task_role" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_app-ecsTaskRole"

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
    SBO_Billing = "nexus_app"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_app_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.ecs_nexus_app_task_execution_role[0].name
  policy_arn = var.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_app_secrets_access_policy_attachment" {
  count      = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_app_task_execution_role[0].name
  policy_arn = aws_iam_policy.sbo_nexus_app_secrets_access.arn
}
