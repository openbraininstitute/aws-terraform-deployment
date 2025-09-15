# Lambda IAM Role
resource "aws_iam_role" "on_demand_worker_lambda_role" {
  name_prefix = "small-scale-simulator-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda policy for CloudWatch metrics, ECS tasks, and logging
resource "aws_iam_policy" "on_demand_worker_lambda_policy" {
  name_prefix = "small-scale-simulator-lambda"
  description = "Policy for on-demand worker Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/small-scale-simulator-on-demand-worker*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "SmallScaleSimulator/JobQueue"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "cloudwatch:namespace" = "SmallScaleSimulator*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:*:cluster/${aws_ecs_cluster.main.name}",
          "arn:aws:ecs:${var.aws_region}:*:task-definition/small-scale-simulator-on-demand-worker-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:*:cluster/${aws_ecs_cluster.main.name}",
          "arn:aws:ecs:${var.aws_region}:*:task/*"
        ]
        Condition = {
          StringEquals = {
            "ecs:cluster" = "arn:aws:ecs:${var.aws_region}:*:cluster/${aws_ecs_cluster.main.name}"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.on_demand_worker_lambda_role.name
  policy_arn = aws_iam_policy.on_demand_worker_lambda_policy.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "on_demand_worker_lambda" {
  name              = "/aws/lambda/small-scale-simulator-on-demand-worker"
  retention_in_days = 14
  kms_key_id        = null
}

# Create the Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/on_demand_worker_lambda.zip"
  source {
    content  = file("${path.module}/lambda_function.py")
    filename = "index.py"
  }
}

# Lambda function
resource "aws_lambda_function" "on_demand_worker" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "small-scale-simulator-on-demand-worker"
  role            = aws_iam_role.on_demand_worker_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ECS_CLUSTER_NAME = aws_ecs_cluster.main.name
      AWS_REGION      = var.aws_region
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    aws_cloudwatch_log_group.on_demand_worker_lambda,
  ]
}

# EventBridge rules for each on-demand worker
resource "aws_cloudwatch_event_rule" "on_demand_worker_schedule" {
  for_each = var.on_demand_workers

  name                = "small-scale-simulator-on-demand-${each.key}"
  description         = "Trigger on-demand worker scaling for ${each.key}"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = var.on_demand_workers

  rule      = aws_cloudwatch_event_rule.on_demand_worker_schedule[each.key].name
  target_id = "TriggerOnDemandWorker"
  arn       = aws_lambda_function.on_demand_worker.arn

  input = jsonencode({
    worker_name       = each.key
    task_definition   = aws_ecs_task_definition.on_demand_worker[each.key].arn
    max_workers      = each.value.max_workers
    capacity_provider = each.value.capacity_provider
    queues           = each.value.queues
    subnets          = [aws_subnet.small_scale_simulator_secondary_a.id, aws_subnet.small_scale_simulator_secondary_b.id]
    security_groups  = [aws_security_group.worker.id]
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = var.on_demand_workers

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.on_demand_worker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.on_demand_worker_schedule[each.key].arn
}
