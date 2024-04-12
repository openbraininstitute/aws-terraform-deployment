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