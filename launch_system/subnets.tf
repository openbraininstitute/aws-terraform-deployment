resource "aws_subnet" "pcs" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = var.pcs_cidr_block
  # need to have a public IP to talk to PCS service
  # https://docs.aws.amazon.com/pcs/latest/userguide/troubleshooting-compute-node-bootstrap.html#:~:text=AWS%20PrivateLink).-,Instance%20in%20a%20public%20subnet%20without%20public%20IP,-If%20your%20subnet 
  # TODO: 
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "pcs-cluster" })
}

resource "aws_vpc_endpoint" "pcs" {
  # endpoint so that the PCS control plane can be reached
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.us-east-1.pcs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.pcs.id]
  security_group_ids = [aws_security_group.pcs_endpoint.id]
}

resource "aws_route_table" "pcs" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.pcs_nat_gateway_id
  }

  tags = {
    Name = "pcs-internet"
  }
}

resource "aws_route_table_association" "pcs" {
  subnet_id      = aws_subnet.pcs.id
  route_table_id = aws_route_table.pcs.id
}
