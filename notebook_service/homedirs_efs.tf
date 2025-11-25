resource "aws_vpc_security_group_ingress_rule" "jupyterhub_efs_sg_ingress" {
  security_group_id = var.jupyterhub_homedirs_efs_security_group_id
  description       = "Allow ingress to jupyterhub homedirs EFS from notebook service security group"

  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_security_group.id
}
