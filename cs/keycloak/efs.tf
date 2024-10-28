# EFS to store keycloak OBI theme https://github.com/BlueBrain/bbop-keycloak-theme
resource "aws_efs_file_system" "keycloak-theme" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false" #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "keycloak-theme"
    SBO_Billing = "keycloak"
  }
}

### Create mount target for keycloak-theme EFS for each subnet
resource "aws_efs_mount_target" "keycloak-theme-mt" {
  count           = length(var.efs_mt_subnets)
  file_system_id  = aws_efs_file_system.keycloak-theme.id
  security_groups = [aws_security_group.efs_sg.id]
  subnet_id       = var.efs_mt_subnets[count.index]
}

# EFS to store keycloak providers (aka plugins)
resource "aws_efs_file_system" "keycloak-providers" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false" #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "keycloak-providers"
    SBO_Billing = "keycloak"
  }
}

resource "aws_efs_mount_target" "keycloak-providers-mt" {
  count           = length(var.efs_mt_subnets)
  file_system_id  = aws_efs_file_system.keycloak-providers.id
  security_groups = [aws_security_group.efs_sg.id]
  subnet_id       = var.efs_mt_subnets[count.index]
}
