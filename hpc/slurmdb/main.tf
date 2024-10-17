# TODO: this was disabled because it conflicts with the already existing instance
#       destroying it would break the current PoC. It needs to be re-enabled when
#       everything is set up cleanly again
#
#       MAKE SURE TO DO THE OTHER TODOS AS WELL!
#
#       search for TODO-SLURMDB throughout the HPC module and in the repo root's main.tf
#
resource "aws_db_subnet_group" "slurm_db_subnet_group" {
  name       = "slurm-db-subnet-group"
  count      = var.create_slurmdb ? 1 : 0
  subnet_ids = var.slurm_db_subnets_ids
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "slurm_database_secret_manager" {
  name        = "slurm_database_password"
  description = "Slurm database password"
}

# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "slurm_database_password" {
  secret_id = var.slurm_mysql_admin_password
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "slurmdb" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058
  count                   = var.create_slurmdb ? 1 : 0
  deletion_protection     = false #tfsec:ignore:AVD-AWS-0177
  allocated_storage       = 5     # in gigabytes
  backup_retention_period = 2     # in days

  db_subnet_group_name = one(aws_db_subnet_group.slurm_db_subnet_group[*].name)

  engine         = "mysql"
  engine_version = "8.0.35"
  multi_az       = false
  instance_class = "db.t3.micro"

  identifier = "hpc-slurm-db"

  username = var.slurm_mysql_admin_username
  password = data.aws_secretsmanager_secret_version.slurm_database_password.secret_string

  publicly_accessible          = false
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data
  performance_insights_enabled = false #tfsec:ignore:aws-rds-enable-performance-insights


  vpc_security_group_ids = [var.slurm_db_sg_id]

  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false # tfsec:ignore:aws-rds-enable-iam-auth
  copy_tags_to_snapshot               = true
}
