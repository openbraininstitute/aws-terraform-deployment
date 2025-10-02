# Subnet
resource "aws_subnet" "obi_one_v2" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.28.0/24"
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "obi_one_v2" })
}

# Link route table to the network
resource "aws_route_table_association" "obi_one_v2" {
  subnet_id      = aws_subnet.obi_one_v2.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_network_acl" "obi_one_v2" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.obi_one_v2.id]
  # Allow access to ssh
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 22
    to_port    = 22
  }
  # Allow access to the container port
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = var.container_port
    to_port    = var.container_port
  }
  # allow ingress ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    # TODO limit to ECR, KMS...
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, { Name = "obi_one_v2" })
}
