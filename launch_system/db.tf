resource "aws_db_subnet_group" "db" {
  name = "launch_system_db_subnet_group"
  subnet_ids = [
    aws_subnet.trusted_a.id,
    aws_subnet.trusted_b.id,
  ]
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = var.secrets_arn
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "main" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058

  engine                      = "postgres"
  engine_version              = "17"
  allow_major_version_upgrade = true
  multi_az                    = true
  instance_class              = var.db_instance_class

  deletion_protection = true #tfsec:ignore:AVD-AWS-0177
  allocated_storage   = var.db_allocated_storage

  db_subnet_group_name = aws_db_subnet_group.db.name

  identifier = "launch-system"
  db_name    = var.db_name
  username   = var.db_username
  password   = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["DB_PASS"]

  publicly_accessible          = false
  performance_insights_enabled = true
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data

  vpc_security_group_ids = [aws_security_group.main.id]

  iam_database_authentication_enabled = false

  copy_tags_to_snapshot = true

  backup_retention_period = 0 # in days
  backup_window           = "01:00-02:00"
  maintenance_window      = "sun:05:00-sun:06:00"

  tags = merge(var.tags, {
    Name            = "launch_system_db"
    obi_backup_plan = var.obi_backup_plan
  })

  lifecycle {
    prevent_destroy = true
  }
}
