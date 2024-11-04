resource "aws_db_subnet_group" "nexus_cluster_subnet_group" {
  name       = "${var.cluster_identifier}-cluster-group"
  subnet_ids = var.subnets_ids
}

# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "nexus_database_password" {
  secret_id = var.nexus_secrets_arn
}

# tfsec:ignore:aws-rds-encrypt-cluster-storage-data
resource "aws_rds_cluster" "nexus" {
  cluster_identifier        = var.cluster_identifier
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  engine                    = "postgres"
  engine_version            = var.nexus_postgresql_engine_version
  db_cluster_instance_class = var.instance_class
  database_name             = var.nexus_postgresql_database_name
  storage_type              = "io1"
  allocated_storage         = 100
  iops                      = 1000
  ca_certificate_identifier = "rds-ca-rsa2048-g1"

  backup_retention_period = 7 # in days
  storage_encrypted       = false

  apply_immediately = true

  performance_insights_enabled = true

  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.nexus_cluster_subnet_group.name
  vpc_security_group_ids = [var.security_group_id]

  master_username = var.nexus_postgresql_database_username
  master_password = jsondecode(data.aws_secretsmanager_secret_version.nexus_database_password.secret_string)["postgres_password"]

  copy_tags_to_snapshot = true
}
