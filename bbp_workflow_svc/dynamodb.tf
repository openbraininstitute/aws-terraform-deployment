# disconnect = ["dynamodb:DeleteItem"]

resource "aws_dynamodb_table" "this" {
  name         = "${local.cluster_name}_id_task"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
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
