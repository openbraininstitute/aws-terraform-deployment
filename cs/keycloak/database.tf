####### DATABASE

resource "aws_db_subnet_group" "keycloak_db_subnet_group" {
  name       = "keycloak-db-subnet-group"
  subnet_ids = var.efs_mt_subnets

  tags = {
    SBO_Billing = "keycloak"
  }
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "keycloak_database_password" {
  name        = "keycloak_database_password"
  description = "Keycloak database password"
}

data "aws_secretsmanager_secret_version" "keycloak_database_password" {
  # TODO danielfr: use aws_secretsmanager_secret.keycloak_database_password.id
  #secret_id = aws_secretsmanager_secret.keycloak_database_password.id
  secret_id = "arn:aws:secretsmanager:us-east-1:671250183987:secret:keycloak_postgresql_password-o9Ybhb"
}

#tfsec:ignore:aws-rds-specify-backup-retention tfsec:ignore:aws-rds-encrypt-instance-storage-data tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "postgres" {
  performance_insights_enabled = true
  deletion_protection          = false #tfsec:ignore:AVD-AWS-0177
  storage_encrypted            = false
  identifier                   = "keycloak-db"
  allocated_storage            = 20
  storage_type                 = "gp2"
  engine                       = "postgres"
  engine_version               = "14"
  instance_class               = var.db_instance_class
  db_name                      = "keycloak_db"
  username                     = "psqladmin"
  password                     = data.aws_secretsmanager_secret_version.keycloak_database_password.secret_string
  publicly_accessible          = false
  multi_az                     = true
  vpc_security_group_ids       = ["sg-05a6965a825b46067"]
  db_subnet_group_name         = aws_db_subnet_group.keycloak_db_subnet_group.name
  copy_tags_to_snapshot        = true
  tags = {
    Name        = "keycloak-db"
    SBO_Billing = "keycloak"
  }
}
