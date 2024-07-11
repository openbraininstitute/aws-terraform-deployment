# The main subnet for Nexus components
resource "aws_subnet" "nexus_main" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.9.0/24"

  tags = {
    "Name"      = "nexus_a"
    SBO_Billing = "nexus"
    Nexus       = "networking"
  }
}

# Route table for the Nexus network
resource "aws_route_table" "nexus" {
  vpc_id = var.vpc_id
}

# Route all traffic whose destination is not the VPC to the NAT Gateway
resource "aws_route" "nexus_nat_route" {
  route_table_id         = aws_route_table.nexus.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# Link route table to the subnet
resource "aws_route_table_association" "nexus" {
  subnet_id      = aws_subnet.nexus_main.id
  route_table_id = aws_route_table.nexus.id
}
