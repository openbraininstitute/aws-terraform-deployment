resource "aws_subnet" "lambda" {
  vpc_id            = var.obp_vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = var.lambda_subnet_cidr
  tags = {
    Name = "lambda"
  }
}

resource "aws_route_table_association" "aws_endpoints" {
  subnet_id      = aws_subnet.lambda.id
  route_table_id = var.endpoints_route_table_id
}
