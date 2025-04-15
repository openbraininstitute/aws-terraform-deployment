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
