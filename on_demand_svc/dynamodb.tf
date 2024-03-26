# API Gateway connection state and task mapping
locals {
  action_to_ddb_ws_conn_task = {
    connect    = ["dynamodb:PutItem"]
    default    = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
    disconnect = ["dynamodb:DeleteItem"]
  }
}

resource "aws_dynamodb_table" "ws_conn_task" {
  name         = "${local.cluster_name}_ws_conn_task"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "conn"
  attribute {
    name = "conn"
    type = "S"
  }
  server_side_encryption {
    enabled     = false #tfsec:ignore:aws-dynamodb-enable-at-rest-encryption
    kms_key_arn = null  #tfsec:ignore:aws-dynamodb-table-customer-key
  }
  point_in_time_recovery {
    enabled = false #tfsec:ignore:aws-dynamodb-enable-recovery
  }
  tags = var.tags
}

data "aws_iam_policy_document" "ddb_ws_conn_task" {
  for_each = local.action_to_ddb_ws_conn_task
  statement {
    resources = [aws_dynamodb_table.ws_conn_task.arn]
    actions   = each.value
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ddb_ws_conn_task" {
  for_each = data.aws_iam_policy_document.ddb_ws_conn_task
  name     = "${var.svc_name}-ddb-ws-conn-task-${each.key}"
  policy   = each.value.json
  tags     = var.tags
}

# ECS task monthly aggregated time per account
resource "aws_dynamodb_table" "ecs_task_acc" {
  name         = "${local.cluster_name}_ecs_task_acc"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "year_month_acc"
  attribute {
    name = "year_month_acc"
    type = "S"
  }
  server_side_encryption {
    enabled     = false #tfsec:ignore:aws-dynamodb-enable-at-rest-encryption
    kms_key_arn = null  #tfsec:ignore:aws-dynamodb-table-customer-key
  }
  point_in_time_recovery {
    enabled = false #tfsec:ignore:aws-dynamodb-enable-recovery
  }
  tags = var.tags
}

data "aws_iam_policy_document" "ddb_ecs_task_acc" {
  statement {
    resources = [aws_dynamodb_table.ecs_task_acc.arn]
    actions   = ["dynamodb:UpdateItem"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ddb_ecs_task_acc" {
  name   = "${var.svc_name}-ddb-ecs-task-acc-disconnect"
  policy = data.aws_iam_policy_document.ddb_ecs_task_acc.json
  tags   = var.tags
}
