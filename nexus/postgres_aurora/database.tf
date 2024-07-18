data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = var.nexus_postgresql_engine_version
}

# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "nexus_database_password" {
  secret_id = var.nexus_database_password_arn
}

resource "aws_db_subnet_group" "nexus_aurora_subnet_group" {
  name       = "nexus-aurora-group"
  subnet_ids = var.subnets_ids
}

# tfsec:ignore:aws-rds-encrypt-cluster-storage-data
module "aurora_postgresql" {
  source  = "terraform-aws-modules/rds-aurora/aws"

  name               = var.nexus_postgresql_name
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  engine             = data.aws_rds_engine_version.postgresql.engine
  engine_mode        = "provisioned"
  engine_version     = data.aws_rds_engine_version.postgresql.version

  apply_immediately = true

  backup_retention_period = 0 # in days
  storage_encrypted       = false

  manage_master_user_password = false
  master_username             = "nexus_user"
  master_password             = data.aws_secretsmanager_secret_version.nexus_database_password.secret_string
  #database_name               = var.nexus_postgresql_database_name

  db_subnet_group_name = aws_db_subnet_group.nexus_aurora_subnet_group.name

  vpc_id = var.vpc_id
  vpc_security_group_ids = [var.security_group_id]

  monitoring_interval = 0

  serverlessv2_scaling_configuration = {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  skip_final_snapshot       = true

  instance_class = "db.serverless"
  instances = {
    1 = {}
    2 = {}
  }

  copy_tags_to_snapshot = true
}