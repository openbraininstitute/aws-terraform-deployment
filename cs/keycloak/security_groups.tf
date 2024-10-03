# Create Security Group for EFS (Allowing all traffic)
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  # Allow all inbound traffic on NFS port (2049) from any source
  ingress {
    description = "Allow ingress from anywhere"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  }

  # Allow all outbound traffic to any destination
  egress {
    description = "Allow egress to anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-vpc-no-public-egress-sgr
  }

  tags = {
    SBO_Billing = "keycloak"
    Name        = "keycloak_efs_sg"
  }
}

resource "aws_security_group" "main_sg" {
  vpc_id      = var.vpc_id
  name        = "keycloak_db_sg"
  description = "main secruity group for keycloak db"

  tags = {
    SBO_Billing = "keycloak"
    Name        = "keycloak_db_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything incoming from the VPC"
  ip_protocol       = -1
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_vpc_security_group_egress_rule" "main_subnet_egress" {
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "keycloak"
  }
}
