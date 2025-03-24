# an s3 bucket to store snapshots is known in the ElasticCloud
# system as a 'repository'.

# resource "ec_snapshot_repository" "repo_ec1" {
#   provider = ec
#   count    = var.create_snapshot_repository ? 1 : 0
#   name     = "shared-snapshot-repository"
#   s3 = {
#     bucket     = var.ec_snapshots_s3_bucket_name
#     access_key = var.ec_snapshots_access_key_id
#     secret_key = var.ec_snapshots_s3_secret_access_key
#     region     = "us-east-1"
#   }
# }

# resource "ec_snapshot_repository" "repo_ec2" {
#   provider = ec.ec2
#   count    = var.create_snapshot_repository ? 1 : 0
#   name     = "shared-snapshot-repository"
#   s3 = {
#     bucket     = var.ec_snapshots_s3_bucket_name
#     access_key = var.ec_snapshots_access_key_id
#     secret_key = var.ec_snapshots_s3_secret_access_key
#     region     = "us-east-1"
#   }
# }
