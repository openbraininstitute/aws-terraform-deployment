#tfsec:ignore:aws-dynamodb-table-customer-key
resource "aws_dynamodb_table" "viz_vsm_jobs_table" {
  name           = "viz-vsm-jobs-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }
  hash_key = "job_id"

  attribute {
    name = "job_id"
    type = "S"
  }
  tags = {
    SBO_Billing = "viz"
  }
}
