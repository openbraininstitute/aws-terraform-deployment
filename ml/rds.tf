resource "aws_security_group" "ml_rds" {
  name   = "ml-rds"
  vpc_id = var.vpc_id

  description = "Machine Learning RDS"
  ingress {
    protocol    = "tcp"
    from_port   = var.rds_port
    to_port     = var.rds_port
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow access from within VPC"
  }

  tags = var.tags
}

#tfsec:ignore:aws-rds-enable-performance-insights
module "ml_rds_postgres" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "ml-rds-postgres"

  engine            = var.rds_engine
  engine_version    = var.rds_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  storage_type      = var.rds_storage_type

  db_name                     = "ml_postgres"
  username                    = var.rds_user
  manage_master_user_password = true
  port                        = var.rds_port
  skip_final_snapshot         = true

  manage_master_user_password_rotation                   = true
  master_user_password_rotation_automatically_after_days = 1
  master_user_password_rotate_immediately                = true


  vpc_security_group_ids = [aws_security_group.ml_rds.id]

  maintenance_window          = "Mon:00:00-Mon:03:00"
  backup_window               = "03:00-06:00"
  create_cloudwatch_log_group = true

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = local.private_subnet_ids

  # DB parameter group
  create_db_parameter_group = false
  family                    = var.rds_param_group

  # Database Deletion Protection
  deletion_protection = false

  tags = var.tags
}