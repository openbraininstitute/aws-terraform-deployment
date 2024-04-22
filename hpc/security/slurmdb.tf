data "aws_vpc" "provided_vpc" {
  id = var.pcluster_vpc_id
}

resource "aws_security_group" "slurm_db_sg" {
  name        = "slurm_db_sg"
  description = "Slurm DB security group"
  count       = var.create_slurmdb ? 1 : 0
  vpc_id      = var.pcluster_vpc_id
}

locals {
  aws_security_group_slurm_db_sg_id = one(aws_security_group.slurm_db_sg[*].id)
}

resource "aws_vpc_security_group_ingress_rule" "MySQL" {
  security_group_id = local.aws_security_group_slurm_db_sg_id
  count             = var.create_slurmdb ? 1 : 0
  cidr_ipv4         = data.aws_vpc.provided_vpc.cidr_block
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}
