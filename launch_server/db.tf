resource "aws_db_subnet_group" "launch_db_cluster_subnet_group" {
  name       = "launch-db-cluster-group"
  subnet_ids = [aws_subnet.launch_db_a.id, aws_subnet.launch_db_b.id]
}

data "aws_secretsmanager_secret_version" "launch_database_password" {
  secret_id = var.launch_service_secrets_arn
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "launch" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058

  engine                      = "postgres"
  engine_version              = "17"
  allow_major_version_upgrade = true
  multi_az                    = true
  instance_class              = "db.t4g.micro"

  deletion_protection = true #tfsec:ignore:AVD-AWS-0177
  allocated_storage   = 50   # in gigabytes

  backup_retention_period = 14 # in days
  backup_window           = "04:00-05:00"
  maintenance_window      = "sun:05:00-sun:06:00"

  db_subnet_group_name = aws_db_subnet_group.launch_db_cluster_subnet_group.name

  identifier = "launch"
  db_name    = var.db_name
  username   = var.db_username
  password   = data.aws_secretsmanager_secret_version.launch_database_password.secret_string

  publicly_accessible          = false
  performance_insights_enabled = true
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data

  vpc_security_group_ids = [aws_security_group.acc_sg.id]

  iam_database_authentication_enabled = false

  copy_tags_to_snapshot = true

  tags = {
    Name            = "launch-db"
    obi_backup_plan = var.obi_backup_plan
  }
}
