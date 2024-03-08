# DynamoDB to persist API Gateway connection state and task mapping
locals {
  action_to_table_perms = {
    connect    = ["dynamodb:PutItem"]
    default    = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
    disconnect = ["dynamodb:DeleteItem"]
  }
}

resource "aws_dynamodb_table" "this" {
  name         = "ws_conn_task"
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

data "aws_iam_policy_document" "ddb_table_perms" {
  for_each = local.action_to_table_perms
  statement {
    resources = [aws_dynamodb_table.this.arn]
    actions   = each.value
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ddb_table_perms" {
  for_each = data.aws_iam_policy_document.ddb_table_perms
  name     = "${var.svc_name}-ddb-table-${each.key}"
  policy   = each.value.json
}
