# Note: this is the filesystem used by the JupyterHub deployment
# on EKS, not the JupyterHub running in the single EC2 VM for
# Polina's notebook.

data "aws_efs_file_system" "homedirs_efs" {
  file_system_id = var.jupyterhub_eks_shared_home_dirs_efs_id
}

locals {
  efs_sg_name = "jupyterhub_homedirs_mount_on_notebook_service"
}

# requested subnet not in same VPC as existing mount targets :-(
# resource "aws_efs_mount_target" "homedirs_efs" {
#   file_system_id  = data.aws_efs_file_system.homedirs_efs.id
#   security_groups = [aws_security_group.homedirs_efs.id]
#   subnet_id       = aws_subnet.ecs_a.id
# }

resource "aws_security_group" "homedirs_efs" {
  name        = local.efs_sg_name
  description = "Security group for mounting the EFS of the JupyterHub homedirs on the notebook service"
  vpc_id      = var.vpc_id
  tags = {
    Name = local.efs_sg_name
  }
}

resource "aws_vpc_security_group_egress_rule" "jupyterhub_efs_sg_egress" {
  security_group_id = aws_security_group.homedirs_efs.id
  description       = "Allow egress to any destination"

  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.ecs_security_group.id

  tags = {
    Name = local.efs_sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "jupyterhub_efs_sg_ingress" {
  security_group_id = aws_security_group.homedirs_efs.id
  description       = "Allow ingress to NFS port from VPC"

  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_security_group.id

  tags = {
    Name = local.efs_sg_name
  }
}

