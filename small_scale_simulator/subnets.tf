# Network used to host API service and Redis
resource "aws_subnet" "small_scale_simulator_primary_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.22.0/27"
  tags = {
    Name = "small_scale_simulator_primary_a"
  }
}

resource "aws_subnet" "small_scale_simulator_primary_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.22.32/27"
  tags = {
    Name = "small_scale_simulator_primary_b"
  }
}

# Network used to host workers
resource "aws_subnet" "small_scale_simulator_secondary_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.22.64/26"
  tags = {
    Name = "small_scale_simulator_secondary_a"
  }
}

resource "aws_subnet" "small_scale_simulator_secondary_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.22.128/26"
  tags = {
    Name = "small_scale_simulator_secondary_b"
  }
}

# TODO: Check if ECS image pull requires internet access, otherwise consider removing
resource "aws_route_table_association" "small_scale_simulator_primary_subnet_a_internet_access" {
  subnet_id      = aws_subnet.small_scale_simulator_primary_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "small_scale_simulator_primary_subnet_b_internet_access" {
  subnet_id      = aws_subnet.small_scale_simulator_primary_b.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "small_scale_simulator_secondary_subnet_a_internet_access" {
  subnet_id      = aws_subnet.small_scale_simulator_secondary_a
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "small_scale_simulator_secondary_subnet_b_internet_access" {
  subnet_id      = aws_subnet.small_scale_simulator_secondary_b
  route_table_id = var.internet_access_route_id
}
