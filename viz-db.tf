resource "aws_security_group" "viz_db_sg" {
  name   = "viz_db_sg"
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  description = "Security group for viz postgresql database"
  # Only PostgreSQL traffic inbound
  /*ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.nexus_app.id]
  }*/
  # for testing allow everything TODO
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow ingress from within vpc"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow egress to within vpc"
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_db_subnet_group" "viz_db_subnet_group" {
  name       = "viz-db-subnet-group"
  subnet_ids = [aws_subnet.viz.id]
  tags = {
    SBO_Billing = "viz"
  }
}

# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "viz_database_password" {
  secret_id = "arn:aws:secretsmanager:us-east-1:671250183987:secret:viz_vsm_db_password-HpmfWe"
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "vizdb" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058
  deletion_protection     = false #tfsec:ignore:AVD-AWS-0177
  allocated_storage       = 5     # in gigabytes
  backup_retention_period = 2     # in days

  count = 1

  db_subnet_group_name = aws_db_subnet_group.viz_db_subnet_group.name

  engine         = "postgres"
  engine_version = "14.7"
  multi_az       = false
  instance_class = "db.t3.small"

  identifier = "viz-vsm-db"
  db_name    = var.viz_postgresql_database_name


  username = var.viz_postgresql_database_username
  password = data.aws_secretsmanager_secret_version.viz_database_password.secret_string

  publicly_accessible          = false
  performance_insights_enabled = true
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data

  vpc_security_group_ids = [aws_security_group.viz_db_sg.id]

  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false
  tags = {
    SBO_Billing = "viz"
  }
}
