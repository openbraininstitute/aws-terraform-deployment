resource "aws_db_subnet_group" "accounting_db_cluster_subnet_group" {
  name       = "accounting-db-cluster-group"
  subnet_ids = [aws_subnet.accounting_db_a.id, aws_subnet.accounting_db_b.id]
  tags = {
    SBO_Billing = "accounting"
  }
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "accounting_database_password" {
  name        = "accounting_database_password"
  description = "Accounting database password"
}

data "aws_secretsmanager_secret_version" "accounting_database_password" {
  secret_id = var.secrets_arn
  # TODO danielfr: replace secret_id by TF managed one
  #secret_id = aws_secretsmanager_secret.accounting_database_password.id
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "accounting" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058

  engine         = "postgres"
  engine_version = "15"
  multi_az       = true
  instance_class = "db.t3.small"

  deletion_protection = true #tfsec:ignore:AVD-AWS-0177
  allocated_storage   = 50   # in gigabytes

  backup_retention_period = 14 # in days
  backup_window           = "04:00-05:00"
  maintenance_window      = "sun:05:00-sun:06:00"

  db_subnet_group_name = aws_db_subnet_group.accounting_db_cluster_subnet_group.name

  identifier = "accounting"
  db_name    = var.db_name
  username   = var.db_username
  password   = data.aws_secretsmanager_secret_version.accounting_database_password.secret_string

  publicly_accessible          = false
  performance_insights_enabled = true
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data

  vpc_security_group_ids = [aws_security_group.acc_sg.id]

  iam_database_authentication_enabled = false

  copy_tags_to_snapshot = true

  tags = {
    Name        = "accounting-db"
    SBO_Billing = "accounting"
  }
}
