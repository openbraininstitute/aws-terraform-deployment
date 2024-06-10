resource "aws_subnet" "lambda" {
  vpc_id            = var.obp_vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = var.lambda_subnet_cidr
  tags = {
    Name = "lambda"
  }
}
