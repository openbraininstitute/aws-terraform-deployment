resource "aws_security_group" "nexus_db" {
  name   = "nexus_db"
  vpc_id = aws_vpc.sbo_poc.id

  description = "Nexus PostgreSQL database"
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
    cidr_blocks = [aws_vpc.sbo_poc.cidr_block]
    description = "allow ingress from within vpc"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_vpc.sbo_poc.cidr_block]
    description = "allow egress to within vpc"
  }
}

resource "aws_db_subnet_group" "nexus_db_subnet_group" {
  name       = "nexus-db-group"
  subnet_ids = [aws_subnet.nexus_db_a.id, aws_subnet.nexus_db_b.id]
}

# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "nexus_database_password" {
  secret_id = "arn:aws:secretsmanager:us-east-1:671250183987:secret:nexus_postgresql_password-jRsJRc"
}

resource "aws_db_instance" "nexusdb" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058
  allocated_storage       = 5 # in gigabytes
  backup_retention_period = 2 # in days

  count = var.create_nexus_database ? 1 : 0

  db_subnet_group_name = aws_db_subnet_group.nexus_db_subnet_group.name

  engine         = "postgres"
  engine_version = "14.6"
  multi_az       = false
  instance_class = "db.t3.small"

  identifier = "nexus-db-id"
  db_name    = var.nexus_postgresql_database_name


  username = var.nexus_postgresql_database_username
  #password = var.nexus_postgresql_database_password
  password = data.aws_secretsmanager_secret_version.nexus_database_password.secret_string

  publicly_accessible = false
  storage_encrypted   = false

  vpc_security_group_ids = [aws_security_group.nexus_db.id]

  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false
}
