# This subnet exists because the Elasticsearch cluster can only be deployed
# in availability zone b for the us-east-1 region.
# for staging is Availability Zone 'a' (nexus_az_letter_id)
# See https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html#ec-private-link-service-names-aliases
# for the list of working availability zones (under "AWS Public Regions")
resource "aws_subnet" "nexus_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}${var.nexus_az_letter_id}"
  cidr_block        = "10.0.10.0/24"

  tags = {
    "Name" = "nexus_b"
  }
}

# Link route table to the subnet
resource "aws_route_table_association" "nexus_b" {
  subnet_id      = aws_subnet.nexus_b.id
  route_table_id = aws_route_table.nexus.id
}
