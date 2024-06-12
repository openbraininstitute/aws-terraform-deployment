# Subnets for the SBO core svc
resource "aws_subnet" "cs_subnet_a" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.13.0/25"
  map_public_ip_on_launch = false

  tags = {
    Name        = "cs_subnet"
    SBO_Billing = "common"
  }
}

resource "aws_subnet" "cs_subnet_b" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}b"
  cidr_block              = "10.0.13.128/25"
  map_public_ip_on_launch = false

  tags = {
    Name        = "cs_subnet"
    SBO_Billing = "common"
  }
}

# Link route table to cs_subnet network
resource "aws_route_table_association" "cs_subnet_a" {
  subnet_id      = aws_subnet.cs_subnet_a.id
  route_table_id = var.route_table_id
}

resource "aws_route_table_association" "cs_subnet_b" {
  subnet_id      = aws_subnet.cs_subnet_b.id
  route_table_id = var.route_table_id
}
