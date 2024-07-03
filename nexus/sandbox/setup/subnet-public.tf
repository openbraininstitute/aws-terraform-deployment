# This public subnet should exist only for environments like sandbox.
# It creates a public subnet that contains a nat gateway and attaches an
# internet gateway to the VPC.

# This subnet can be reached from the internet.
# The other subnets should allow at most inbound traffic from the VPC; this is
# handled by the security group.

resource "aws_vpc" "sandbox" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.sandbox.id
  cidr_block        = "10.0.1.0/25"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.sandbox.id
  cidr_block        = "10.0.1.128/25"
  availability_zone = "${var.aws_region}b"
}

resource "aws_nat_gateway" "sandbox" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_a.id
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sandbox.id
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.sandbox.id
}

resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public.id
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
