resource "aws_subnet" "launch_db_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.29.0/28"
  tags = {
    Name = "launch_db_a"
  }
}

resource "aws_subnet" "launch_db_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.29.16/28"
  tags = {
    Name = "launch_db_b"
  }
}

resource "aws_subnet" "launch_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.23.32/27"
  tags = {
    Name = "launch_ecs_a"
  }
}

resource "aws_subnet" "launch_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.23.64/27"
  tags = {
    Name = "launch_ecs_b"
  }
}

# give access to the internet for ECR
resource "aws_route_table_association" "launch_ecs_a_internet_access" {
  subnet_id      = aws_subnet.launch_ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "launch_ecs_b_internet_access" {
  subnet_id      = aws_subnet.launch_ecs_b.id
  route_table_id = var.internet_access_route_id
}
