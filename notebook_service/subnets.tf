resource "aws_subnet" "ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = var.ecs_cidr_block_a
  tags = {
    Name = "notebook_service_a"
  }
}

resource "aws_subnet" "ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = var.ecs_cidr_block_b
  tags = {
    Name = "notebook_service_b"
  }
}

# Setup routing table
resource "aws_route_table_association" "ecs_a_routing" {
  subnet_id      = aws_subnet.ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "ecs_b_routing" {
  subnet_id      = aws_subnet.ecs_b.id
  route_table_id = var.internet_access_route_id
}


resource "aws_network_acl" "network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.ecs_a.id, aws_subnet.ecs_b.id]
  ingress {
    protocol   = "tcp"
    rule_no    = 10
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.main.cidr_block # HTTP
    from_port  = 8000
    to_port    = 8000
  }
  ingress {
    protocol   = -1
    rule_no    = 101
    action     = "allow"
    cidr_block = data.aws_vpc.main.cidr_block # Prometheus endpoint
    from_port  = 9464
    to_port    = 9464
  }
  ingress {
    protocol   = "udp"
    rule_no    = 300
    action     = "allow"
    cidr_block = data.aws_vpc.main.cidr_block # ephemeral ports for DNS
    from_port  = 1024
    to_port    = 65535
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 301
    action     = "allow"
    cidr_block = "0.0.0.0/0" # ephemeral ports for regular traffic
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "notebook_service"
  }
}
