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

