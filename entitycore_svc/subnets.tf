resource "aws_subnet" "entitycore_db_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.23.0/28"
  tags = {
    Name = "entitycore_db_a"
  }
}

resource "aws_subnet" "entitycore_db_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.23.16/28"
  tags = {
    Name = "entitycore_db_b"
  }
}

resource "aws_subnet" "entitycore_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.23.32/27"
  tags = {
    Name = "entitycore_ecs_a"
  }
}

resource "aws_subnet" "entitycore_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.23.64/27"
  tags = {
    Name = "entitycore_ecs_b"
  }
}
