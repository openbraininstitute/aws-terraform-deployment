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
