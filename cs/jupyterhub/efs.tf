# EFS to store JupyterHub users HOMEDIRS
resource "aws_efs_file_system" "jupyterhub_homedirs" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  tags = {
    Name        = "jupyterhub_svc"
    SBO_Billing = "jupyterhub_svc"
  }
}

resource "aws_efs_backup_policy" "jupyterhub_homedirs_backup_policy" {
  file_system_id = aws_efs_file_system.jupyterhub_homedirs.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "jupyterhub_homedirs_mt" {
  file_system_id  = aws_efs_file_system.jupyterhub_homedirs.id
  security_groups = [aws_security_group.jupyterhub_efs_sg.id]
  subnet_id       = var.jupyterhub_private_subnet
}
