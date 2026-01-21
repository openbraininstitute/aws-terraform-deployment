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
  description = "Allows ECS tasks to call AWS services on your behalf"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.keycloak_aws_otel_collector.name}*",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.keycloak_ecs_task.name}*"
        ]
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

resource "aws_iam_role_policy_attachment" "secret_access_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

# got them from https://raw.githubusercontent.com/aws-observability/aws-otel-collector/main/deployment-template/ecs/aws-otel-fargate-sidecar-deployment-cfn.yaml
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# to be able to send scraped metrics to Amazon Managed Service for Prometheus
resource "aws_iam_role_policy_attachment" "ecs_task_prometheus_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}


