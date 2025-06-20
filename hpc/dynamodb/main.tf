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

resource "aws_dynamodb_table" "pcluster_dynamo_table" {
  name = "pclusters"

  attribute {
    name = "name"
    type = "S"
  }

  # attribute {
  #   name = "project_id"
  #   type = "S"
  # }

  # attribute {
  #   name = "vlab_id"
  #   type = "S"
  # }

  # attribute {
  #   name = "tier"
  #   type = "S"
  # }

  # attribute {
  #   name = "benchmark"
  #   type = "N"
  # }

  # attribute {
  #   name = "dev"
  #   type = "N"
  # }

  # attribute {
  #   name = "include_lustre"
  #   type = "N"
  # }

  # attribute {
  #   name = "sim_pubkey"
  #   type = "S"
  # }

  # attribute {
  #   name = "admin_ssh_key_name"
  #   type = "S"
  # }

  attribute {
    name = "provisioning_launched"
    type = "N"
  }

  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = var.is_production
  hash_key                    = "name"

  global_secondary_index {
    name               = "ClaimIndex"
    hash_key           = "provisioning_launched"
    projection_type    = "INCLUDE"
    non_key_attributes = ["name", "project_id", "vlab_id", "tier", "benchmark", "dev", "include_lustre", "sim_pubkey", "admin_ssh_key_name"]
  }

}
