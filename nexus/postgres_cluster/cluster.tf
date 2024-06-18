# TODO the secret should be defined in the code
# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "nexus_database_password" {
  secret_id = var.nexus_postgresql_database_password_arn
}

# tfsec:ignore:aws-rds-encrypt-cluster-storage-data
resource "aws_rds_cluster" "nexus" {
  cluster_identifier        = "nexus"
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  engine                    = "postgres"
  engine_version            = "15"
  db_cluster_instance_class = var.instance_class
  storage_type              = "io1"
  allocated_storage         = 50
  iops                      = 1000

  backup_retention_period = 7 # in days
  storage_encrypted       = false

  vpc_security_group_ids = [var.security_group_id]

  master_username = var.nexus_postgresql_database_username
  master_password = data.aws_secretsmanager_secret_version.nexus_database_password.secret_string

  copy_tags_to_snapshot = true
  snapshot_identifier   = "arn:aws:rds:us-east-1:671250183987:snapshot:nexus-second-db"
}