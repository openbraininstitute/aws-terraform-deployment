#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "keycloak_ecs_execute_command" {
  name = "keycloak-ecsTaskExecutionRole"
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

  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_iam_role_policy_attachment" "keycloak_execute_command_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.keycloak_ecs_execute_command.arn
}

resource "aws_iam_role_policy_attachment" "keycloak_secret_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.access_keycloak_secrets.arn
}

resource "aws_iam_policy" "ecsTaskLogs" {
  name        = "keycloak-ecsTaskLogs"
  description = "Allows ECS tasks to create log streams and log groups in CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:*"
      }
    ]
  })

  tags = {
    SBO_Billing = "keycloak"
  }
}

### IAM roles and policies needed for keyloak-task logging
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "keycloak-ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    SBO_Billing = "keycloak"
  }
}

#### We need to attach following policies to the role task_execution_role. The same role should execute the task and fetch secrets from secret manager (db password)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecsTaskLogs.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secret_access_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
