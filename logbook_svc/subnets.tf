# Two AZs for the tasks and two for the data stores: RDS and ElastiCache
# subnet groups need at least two AZs, and a task in each AZ keeps live
# editing up when one AZ fails. /27 = 27 usable IPs per AZ for tasks
# (one ENI each, plus the doubled count during a rolling deploy); /28 =
# 11 usable IPs for the RDS instance (+ its Multi-AZ standby) and the
# Redis node.

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

# give access to the internet for ECR, Keycloak and EntityCore (shared NAT)
resource "aws_route_table_association" "logbook_ecs_a_internet_access" {
  subnet_id      = aws_subnet.logbook_ecs_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "logbook_ecs_b_internet_access" {
  subnet_id      = aws_subnet.logbook_ecs_b.id
  route_table_id = var.internet_access_route_id
}
