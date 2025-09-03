#tfsec:ignore:aws-dynamodb-enable-at-rest-encryption
#tfsec:ignore:aws-dynamodb-enable-recovery
#tfsec:ignore:aws-dynamodb-table-customer-key
# resource "aws_dynamodb_table" "pcluster_deployments_dynamo_table" {
#   name = "sbo-parallelcluster-deployments"
#   attribute {
#     name = "type"
#     type = "S"
#   }
#   billing_mode                = "PAY_PER_REQUEST"
#   deletion_protection_enabled = true
#   hash_key                    = "type"
#   tags = {
#     SBO_Billing = "hpc:parallelcluster"
#   }
# }


#tfsec:ignore:aws-dynamodb-enable-at-rest-encryption
#tfsec:ignore:aws-dynamodb-enable-recovery
#tfsec:ignore:aws-dynamodb-table-customer-key
resource "aws_dynamodb_table" "pcluster_subnets_dynamo_table" {
  name = "sbo-parallelcluster-subnets"
  attribute {
    name = "subnet_id"
    type = "S"
  }
  attribute {
    name = "cluster"
    type = "S"
  }
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = var.is_production
  hash_key                    = "subnet_id"
  global_secondary_index {
    name               = "ClusterIndex"
    hash_key           = "cluster"
    projection_type    = "INCLUDE"
    non_key_attributes = ["subnet_id"]
  }
}
