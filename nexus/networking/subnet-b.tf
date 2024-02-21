# Subnet for Nexus
resource "aws_subnet" "nexus_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.10.0/24"
  tags = {
    Name        = "nexus_b"
    SBO_Billing = "nexus"
  }
}

# Link route table to nexus_app network
resource "aws_route_table_association" "nexus_b" {
  subnet_id      = aws_subnet.nexus_b.id
  route_table_id = aws_route_table.nexus.id
}