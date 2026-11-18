resource "aws_db_parameter_group" "logbook" {
  name_prefix = "logbook"
  family      = "postgres18" # the schema needs PostgreSQL 18 for uuidv7()

  lifecycle {
    create_before_destroy = true
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1" # already the default on PostgreSQL 15+; set anyway: no plain-text connections
  }

  parameter {
    name  = "random_page_cost"
    value = "1.1" # default 4 is for spinning disks; gp3 is SSD
  }

  parameter {
    name  = "effective_io_concurrency"
    value = "200" # default 1; SSD serves many reads at once
  }
}

resource "aws_db_subnet_group" "logbook" {
  name       = "logbook-db-subnet-group"
  subnet_ids = [aws_subnet.logbook_data_a.id, aws_subnet.logbook_data_b.id]
}

data "aws_secretsmanager_secret_version" "logbook" {
  secret_id = var.logbook_service_secrets_arn
}

resource "aws_db_instance" "logbook" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058

  engine         = "postgres"
  engine_version = "18" # RDS picks the default 18.x minor; minor upgrades happen in the maintenance window
  multi_az       = var.db_multi_az
  instance_class = var.db_instance_class

  deletion_protection = true #tfsec:ignore:AVD-AWS-0177


  storage_type          = "gp3"
  allocated_storage     = 20  # in gigabytes; the gp3 minimum
  max_allocated_storage = 200 # in gigabytes

  backup_retention_period = 0 # in days
  backup_window           = "01:00-02:00"
  maintenance_window      = "sun:05:00-sun:06:00"

  db_subnet_group_name = aws_db_subnet_group.logbook.name
  parameter_group_name = aws_db_parameter_group.logbook.name

  identifier = "logbook"
  db_name    = var.db_name
  username   = var.db_username
  password   = jsondecode(data.aws_secretsmanager_secret_version.logbook.secret_string)["DB_PASS"]

  publicly_accessible = false


  storage_encrypted = true

  vpc_security_group_ids = [aws_security_group.logbook_db.id]

  iam_database_authentication_enabled = false

  copy_tags_to_snapshot = true

  tags = {
    Name            = "logbook-db"
    obi_backup_plan = var.obi_backup_plan
  }

  lifecycle {
    prevent_destroy = true
  }
}
