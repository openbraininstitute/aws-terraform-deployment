resource "aws_efs_file_system" "users_homedirs" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name        = "jupyterhub-svc-efs"
    SBO_Billing = "jupyterhub_svc"
  }
}

resource "aws_security_group" "efs_homedirs_sg" {
  name        = "${var.jupyterhub_eks_cluster_name}-efs-sg"
  description = "EFS access for EKS ${var.jupyterhub_eks_cluster_name}"
  vpc_id      = var.vpc_id
  tags        = { SBO_Billing = "jupyterhub_svc" }
}


resource "aws_security_group_rule" "efs_homedirs_allow_cluster" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = data.aws_eks_cluster.jupyterhub[0].vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.efs_homedirs_sg.id

  count = var.is_staging ? 1 : 1
}

resource "aws_efs_mount_target" "users_homedirs_a" {
  file_system_id = aws_efs_file_system.users_homedirs.id
  subnet_id      = aws_subnet.jupyterhub_eks_private_a.id

  security_groups = [
    aws_security_group.efs_homedirs_sg.id,
  ]
  count = var.is_staging ? 1 : 1
}

resource "aws_efs_mount_target" "users_homedirs_b" {
  file_system_id = aws_efs_file_system.users_homedirs.id
  subnet_id      = aws_subnet.jupyterhub_eks_private_b.id

  security_groups = [
    aws_security_group.efs_homedirs_sg.id,
  ]
  count = var.is_staging ? 1 : 1
}
