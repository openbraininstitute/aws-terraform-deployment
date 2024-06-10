resource "aws_subnet" "lambda" {
  vpc_id            = var.obp_vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "172.31.2.0/24"
  tags = {
    Name = "lambda"
  }
}
