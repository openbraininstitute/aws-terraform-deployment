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
  secret_id = aws_secretsmanager_secret.keycloak_database_password.id
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "access_keycloak_secrets" {
  name        = "keycloak-secrets-access-policy"
  description = "Policy that gives access to the Keycloak secrets"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.keycloak_database_password.arn}"
      ]
    }
  ]
}
EOF
}

#tfsec:ignore:aws-rds-specify-backup-retention tfsec:ignore:aws-rds-encrypt-instance-storage-data tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "keycloak_database" {
  performance_insights_enabled = true
  deletion_protection          = false #tfsec:ignore:AVD-AWS-0177
  storage_encrypted            = false
  identifier                   = "keycloak"
  allocated_storage            = 20
  storage_type                 = "gp2"
  engine                       = "postgres"
  engine_version               = "14"
  instance_class               = var.db_instance_class
  db_name                      = "keycloak"
  username                     = "keycloak"
  password                     = data.aws_secretsmanager_secret_version.keycloak_database_password.secret_string
  publicly_accessible          = false
  multi_az                     = true
  vpc_security_group_ids       = [aws_security_group.main_sg.id]
  db_subnet_group_name         = aws_db_subnet_group.keycloak_db_subnet_group.name
  copy_tags_to_snapshot        = true
  tags = {
    Name        = "keycloak-db"
    SBO_Billing = "keycloak"
  }
}
