# Two AZs: RDS and ElastiCache need them, and a task per AZ keeps editing up if one AZ fails.
# /27 fits twice the tasks during a rolling deploy; /28 fits RDS, its standby and Redis.

resource "aws_subnet" "logbook_ecs_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = var.ecs_cidr_block_a
  tags = {
    Name = "logbook_ecs_a"
  }
}

resource "aws_subnet" "logbook_ecs_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = var.ecs_cidr_block_b
  tags = {
    Name = "logbook_ecs_b"
  }
}

resource "aws_subnet" "logbook_data_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = var.data_cidr_block_a
  tags = {
    Name = "logbook_data_a"
  }
}

resource "aws_subnet" "logbook_data_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = var.data_cidr_block_b
  tags = {
    Name = "logbook_data_b"
  }
}

# Internet through the shared NAT, for ECR, Keycloak and EntityCore.
resource "aws_route_table_association" "logbook_ecs_a_internet_access" {
  subnet_id      = aws_subnet.logbook_ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "logbook_ecs_b_internet_access" {
  subnet_id      = aws_subnet.logbook_ecs_b.id
  route_table_id = var.internet_access_route_id
}
