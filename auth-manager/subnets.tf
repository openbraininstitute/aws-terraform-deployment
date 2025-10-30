resource "aws_subnet" "auth_manager_db_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.24.0/28"
  tags = {
    Name = "auth_manager_db_a"
  }
}

resource "aws_subnet" "auth_manager_db_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.24.16/28"
  tags = {
    Name = "auth_manager_db_b"
  }
}

resource "aws_subnet" "auth_manager_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.24.32/27"
  tags = {
    Name = "auth_manager_ecs_a"
  }
}

resource "aws_subnet" "auth_manager_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.24.64/27"
  tags = {
    Name = "auth_manager_ecs_b"
  }
}

resource "aws_route_table_association" "auth_manager_ecs_subnet_a" {
  subnet_id      = aws_subnet.auth_manager_ecs_a.id
  route_table_id = var.route_table_id
}

resource "aws_route_table_association" "auth_manager_ecs_subnet_b" {
  subnet_id      = aws_subnet.auth_manager_ecs_b.id
  route_table_id = var.route_table_id
}
