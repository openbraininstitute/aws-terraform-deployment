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
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "nexus_ecs_execute_command" {
  name = "nexus-ecsTaskExecutionRole"
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nexus_execute_command_access" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = aws_iam_policy.nexus_ecs_execute_command.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "cloudwatch_write_policy" {
  name        = "NexusCloudwatchWritePolicy"
  description = "A policy that grants write access to Cloudwatch logs"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_service" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "nexus_secret_access" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = aws_iam_policy.access_nexus_secrets.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_write_logs" {
  role       = aws_iam_role.nexus_ecs_task_execution.name
  policy_arn = aws_iam_policy.cloudwatch_write_policy.arn
}