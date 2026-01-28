resource "aws_subnet" "bastion" {
  vpc_id            = var.vpc_id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = "10.0.31.0/28"
  tags = {
    Name = "bastion_host"
  }
}

resource "aws_route_table_association" "bastion" {
  subnet_id      = aws_subnet.bastion.id
  route_table_id = var.route_table_private_subnets_id
}
