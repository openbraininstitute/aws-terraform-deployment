
### create efs volume to import keycloak.conf file and TLS certs
resource "aws_efs_file_system" "keycloakfs" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false" #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "keycloak"
    SBO_Billing = "keycloak"
  }
}

### Create mount target for EFS for each subnet
resource "aws_efs_mount_target" "efs-mt" {
  count           = length(var.efs_mt_subnets)
  file_system_id  = aws_efs_file_system.keycloakfs.id
  security_groups = [aws_security_group.efs_sg.id]
  subnet_id       = var.efs_mt_subnets[count.index]
}

output "efs_arn" {
  value = aws_efs_file_system.keycloakfs.arn
}

# INFRA-9832 Create efs for keycloak theme
resource "aws_efs_file_system" "keycloak-theme" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false" #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "keycloak-theme"
    SBO_Billing = "keycloak"
  }
}

### Create mount target for keycloak theme EFS for each subnet
resource "aws_efs_mount_target" "keycloak-theme-mt" {
  count           = length(var.efs_mt_subnets)
  file_system_id  = aws_efs_file_system.keycloak-theme.id
  security_groups = [aws_security_group.efs_sg.id]
  subnet_id       = var.efs_mt_subnets[count.index]
}

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
