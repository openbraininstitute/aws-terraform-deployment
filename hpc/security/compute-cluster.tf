# Bring the default security group under Terraform management
resource "aws_default_security_group" "default" {
  vpc_id = var.obp_vpc_id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnet" "slurm_db_a" {
  id    = var.slurm_db_a_subnet_id
  count = var.create_slurmdb ? 1 : 0
}

resource "aws_security_group" "jumphost" {
  name        = "jumphost"
  count       = var.create_jumphost ? 1 : 0
  vpc_id      = var.obp_vpc_id
  description = "Security group for jumphost"
}

resource "aws_security_group" "peering" {
  name        = "peering"
  vpc_id      = var.obp_vpc_id
  description = "Security group for VPC peering traffic"
}

resource "aws_vpc_security_group_egress_rule" "peering_allow_egress" {
  security_group_id = aws_security_group.peering.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  description = "allow traffic to peering VPC"
  cidr_ipv4   = "172.32.0.0/16"
}

locals {
  aws_security_group_jumphost_id = one(aws_security_group.jumphost[*].id)
}

resource "aws_vpc_security_group_egress_rule" "jumphost_allow_egress" {
  security_group_id = local.aws_security_group_jumphost_id

  count       = var.create_jumphost ? 1 : 0
  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  description = "allow outbound traffic"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "jumphost_allow_ingress_ssh" {
  security_group_id = local.aws_security_group_jumphost_id

  count       = var.create_jumphost ? 1 : 0
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  description = "allow ssh access"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "jumphost_allow_local_ingress" {
  security_group_id = local.aws_security_group_jumphost_id

  count       = var.create_jumphost ? 1 : 0
  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  description = "allow local access"
  cidr_ipv4   = data.aws_vpc.provided_vpc.cidr_block
}

resource "aws_security_group" "hpc" {
  name   = "hpc"
  vpc_id = var.pcluster_vpc_id

  description = "SBO HPC"

  tags = {
    Name     = "sbo-poc-compute-hpc-sg"
    HPC_Goal = "compute_cluster"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hpc_allow_sg_ingress" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol                  = -1
  from_port                    = -1
  to_port                      = -1
  referenced_security_group_id = aws_security_group.hpc.id
  description                  = "allow ingress within security group"
}

resource "aws_vpc_security_group_egress_rule" "hpc_allow_sg_egress" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol                  = -1
  from_port                    = -1
  to_port                      = -1
  referenced_security_group_id = aws_security_group.hpc.id
  description                  = "allow egress within security group"
}

resource "aws_vpc_security_group_ingress_rule" "hpc_allow_peering_ingress" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  cidr_ipv4   = data.aws_vpc.peering_vpc.cidr_block
  description = "allow ingress from peered vpc"
}

resource "aws_vpc_security_group_ingress_rule" "hpc_allow_local_ingress" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  cidr_ipv4   = data.aws_vpc.provided_vpc.cidr_block
  description = "allow ingress within vpc"
}

resource "aws_vpc_security_group_egress_rule" "hpc_allow_local_egress" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  cidr_ipv4   = data.aws_vpc.provided_vpc.cidr_block
  description = "allow egress within vpc"
}

resource "aws_vpc_security_group_egress_rule" "hpc_allow_https" {
  security_group_id = aws_security_group.hpc.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
  description = "allow https"
}

resource "aws_security_group" "compute_efs" {
  name   = "compute_efs_sg"
  vpc_id = var.pcluster_vpc_id

  description = "SBO compute EFS filesystem"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.aws_vpc.provided_vpc.cidr_block]
    description = "allow ingress within vpc"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.aws_vpc.provided_vpc.cidr_block]
    description = "allow egress within vpc"
  }
}


resource "aws_security_group" "hpc_efa" {
  name   = "hpc_efa_fg"
  vpc_id = var.pcluster_vpc_id

  description = "EFA-enabled security group for cluster"

  ingress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    self        = true
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    self        = true
  }

  tags = {
    Name = "sbo-poc-compute-sg"
  }
}
