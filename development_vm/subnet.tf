resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc_id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = var.subnet_cidr_block
  tags = {
    Name = var.subnet_name
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route_table_private_subnets_id
}
