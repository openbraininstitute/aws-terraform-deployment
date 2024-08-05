resource "aws_subnet" "accounting_db_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.17.0/28"
  tags = {
    Name          = "accounting_db_a"
    "SBO_Billing" = "accounting"
  }
}

resource "aws_subnet" "accounting_db_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.17.16/28"
  tags = {
    Name          = "accounting_db_b"
    "SBO_Billing" = "accounting"
  }
}

resource "aws_subnet" "accounting_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.17.32/27"
  tags = {
    Name          = "accounting_ecs_a"
    "SBO_Billing" = "accounting"
  }
}

resource "aws_subnet" "accounting_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.17.64/27"
  tags = {
    Name          = "accounting_ecs_b"
    "SBO_Billing" = "accounting"
  }
}

# give access to the internet so dockerhub can be reached
resource "aws_route_table_association" "accounting_ecs_a_docker_access" {
  subnet_id      = aws_subnet.accounting_ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "accounting_ecs_b_docker_access" {
  subnet_id      = aws_subnet.accounting_ecs_b.id
  route_table_id = var.internet_access_route_id
}
