resource "aws_security_group" "virtual_lab_manager_db_sg" {
  name   = "virtual_lab_manager_db_sg"
  vpc_id = var.vpc_id

  description = "Security group for virtual lab manager Postgresql database"

  ingress {
    description = "Allow Postgres access from the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_source_ip_cidr_blocks
  }

  tags = var.virtual_lab_manager_tags
}

resource "aws_db_subnet_group" "virtual_lab_manager_db_subnet_group" {
  name       = "virtual-lab-manager-db-subnet-group"
  subnet_ids = [aws_subnet.virtual_lab_manager_a.id, aws_subnet.virtual_lab_manager_b.id]

  tags = var.virtual_lab_manager_tags
}

data "aws_secretsmanager_secret_version" "virtual_lab_manager_secrets" {
  secret_id = var.virtual_lab_manager_secrets_arn
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "virtual_lab_manager" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058
  deletion_protection     = true #tfsec:ignore:AVD-AWS-0177
  allocated_storage       = 5    # in gigabytes
  backup_retention_period = 0    # in days

  apply_immediately = false

  db_subnet_group_name = aws_db_subnet_group.virtual_lab_manager_db_subnet_group.name

  engine                     = "postgres"
  engine_version             = "17.9"
  auto_minor_version_upgrade = true
  multi_az                   = var.db_multi_az
  instance_class             = "db.t3.small"

  identifier = "virtual-lab-manager-db-id"
  db_name    = var.virtual_lab_manager_postgres_db
  username   = var.virtual_lab_manager_postgres_user
  password   = jsondecode(data.aws_secretsmanager_secret_version.virtual_lab_manager_secrets.secret_string)["database_password"]

  publicly_accessible          = false
  performance_insights_enabled = true
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data

  vpc_security_group_ids = [aws_security_group.virtual_lab_manager_db_sg.id]

  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false

  copy_tags_to_snapshot = true

  tags = merge(var.virtual_lab_manager_tags, { obi_backup_plan = "obi_plan" })
}
