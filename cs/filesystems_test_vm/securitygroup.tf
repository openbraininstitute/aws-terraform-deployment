data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "filesystems_test_vm_sg" {
  name        = "filesystems_test_vm_sg"
  description = "Security group for VM to test filesystems speed"
  vpc_id      = var.vpc_id
  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "filesystems_test_vm_sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "filesystems_test_vm_sg_egress" {
  security_group_id = aws_security_group.filesystems_test_vm_sg.id
  description       = "Allow egress to any destination"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "allow egress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "filesystems_test_vm_sg_ssh_ingress" {
  security_group_id = aws_security_group.filesystems_test_vm_sg.id
  description       = "Allow ingress for ssh"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "allow ssh"
  }
}
