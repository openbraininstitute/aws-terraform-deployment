# EFS to store JupyterHub users HOMEDIRS
resource "aws_efs_file_system" "jupyterhub_homedirs" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false" #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "jupyterhub_svc"
    SBO_Billing = "jupyterhub_svc"
  }
}

resource "aws_efs_mount_target" "jupyterhub_homedirs_mt" {
  file_system_id  = aws_efs_file_system.jupyterhub_homedirs.id
  security_groups = [aws_security_group.jupyterhub_efs_sg.id]
  subnet_id       = var.jupyterhub_private_subnet
}
