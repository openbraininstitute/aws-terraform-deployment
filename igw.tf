# Gateway for routed (not-NAT) traffic
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.sbo_poc.id
  tags = {
    Name        = "igw"
    SBO_Billing = "common"
  }
}
