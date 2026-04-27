resource "aws_security_group" "main" {
  vpc_id = var.vpc_id

  name        = "launch_system_main"
  description = "Main security group for launch system"
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  security_group_id = aws_security_group.main.id
  description       = "Allow everything incoming from the VPC"
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "main_subnet_egress" {
  security_group_id = aws_security_group.main.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
}

resource "aws_security_group" "pcs_endpoint" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.pcs.cidr_block]
  }
  tags = { Name = "pcs-endpoint-sg" }
}

resource "aws_security_group" "pcs" {
  name        = "pcs-cluster-sg"
  description = "Security group for PCS cluster"
  vpc_id      = var.vpc_id

  tags = { Name = "pcs-cluster-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.pcs.id
  description       = "SSH"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.vpc_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "slurmrestd" {
  security_group_id = aws_security_group.pcs.id
  description       = "slurmrestd"
  ip_protocol       = "tcp"
  from_port         = 6820
  to_port           = 6820
  cidr_ipv4         = var.vpc_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "lustre_lnet" {
  security_group_id = aws_security_group.pcs.id
  description       = "Lustre LNET network traffic"
  ip_protocol       = "tcp"
  from_port         = 988
  to_port           = 988
  cidr_ipv4         = var.pcs_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "lustre_client" {
  security_group_id = aws_security_group.pcs.id
  description       = "Lustre client communication"
  ip_protocol       = "tcp"
  from_port         = 1021
  to_port           = 1023
  cidr_ipv4         = var.pcs_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "slurm_slurmctld" {
  security_group_id = aws_security_group.pcs.id
  ip_protocol       = "tcp"
  description       = "Port 6817 for slurmd to communicate with slurmctld"
  from_port         = 6817
  to_port           = 6817
  cidr_ipv4         = var.pcs_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "slurm_slurmd" {
  security_group_id = aws_security_group.pcs.id
  ip_protocol       = "tcp"
  description       = "Port 6818 for slurmctld to ping slurmd"
  from_port         = 6818
  to_port           = 6818
  cidr_ipv4         = var.pcs_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "slurm_api" {
  security_group_id = aws_security_group.pcs.id
  ip_protocol       = "tcp"
  from_port         = 6820
  to_port           = 6820
  cidr_ipv4         = var.pcs_cidr_block
}

# all slurm nodes need to be able to talk to each other; so open all ephemeral ports
resource "aws_vpc_security_group_ingress_rule" "slurm_internode" {
  security_group_id = aws_security_group.pcs.id
  ip_protocol       = "tcp"
  from_port         = 1024
  to_port           = 65535
  cidr_ipv4         = var.pcs_cidr_block
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.pcs.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EFA wants have a self-referencing security-group for ingress...
# see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start.html#efa-start-security
resource "aws_vpc_security_group_ingress_rule" "efa_self" {
  security_group_id            = aws_security_group.pcs.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.pcs.id
  description                  = "EFA self-referencing Ingress"
}

# ... and egress
resource "aws_vpc_security_group_egress_rule" "efa_self" {
  security_group_id            = aws_security_group.pcs.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.pcs.id
  description                  = "EFA self-referencing Egress"
}

