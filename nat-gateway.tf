resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]
  count         = var.create_nat_gateway ? 1 : 0

  tags = {
    Name        = "nat"
    SBO_Billing = "common"
  }
}

resource "aws_eip" "nat_eip" {
  vpc   = true
  count = var.create_nat_gateway ? 1 : 0

  tags = {
    Name        = "nat_eip"
    SBO_Billing = "common"
  }
}
