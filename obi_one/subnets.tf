resource "aws_subnet" "obi_one_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.24.32/27"
  tags = {
    Name = "obi_one_ecs_a"
  }
}

resource "aws_subnet" "obi_one_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.24.64/27"
  tags = {
    Name = "obi_one_ecs_b"
  }
}

# give access to the internet for ECR
resource "aws_route_table_association" "obi_one_ecs_a_internet_access" {
  subnet_id      = aws_subnet.obi_one_ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "obi_one_ecs_b_internet_access" {
  subnet_id      = aws_subnet.obi_one_ecs_b.id
  route_table_id = var.internet_access_route_id
}

resource "aws_network_acl" "obi_one_nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.obi_one_ecs_a.id, aws_subnet.obi_one_ecs_b.id]
  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.main.cidr_block
    from_port  = var.container_port
    to_port    = var.container_port
    protocol   = "tcp"
  }
  # allow ingress to ephemeral ports
  ingress {
    rule_no    = 150
    action     = "allow"
    cidr_block = data.aws_vpc.main.cidr_block
    from_port  = 1024
    to_port    = 65535
    protocol   = "tcp"
  }
  egress {
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = -1
  }
  tags = {
    Name        = "obi_one_nacl"
    SBO_Billing = "obi_one"
  }
}
