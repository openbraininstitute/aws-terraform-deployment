# Subnet for the Nexus databases and storage
resource "aws_subnet" "nexus_db_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.48/28"
  tags = {
    Name        = "nexus_db_a"
    SBO_Billing = "nexus"
  }
}
# Subnet for the Nexus databases and storage
resource "aws_subnet" "nexus_db_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.2.64/28"
  tags = {
    Name        = "nexus_db_b"
    SBO_Billing = "nexus"
  }
}

resource "aws_network_acl" "nexus_db" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.nexus_db_a.id, aws_subnet.nexus_db_b.id]
  # TODO limit to correct ports and subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.provided_vpc.cidr_block
    from_port  = 5432
    to_port    = 5432
  }
  egress {
    # TODO can be removed? Or needs access to secrets manager?
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.provided_vpc.cidr_block
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "nexus_db_acl"
    SBO_Billing = "nexus"
  }
}