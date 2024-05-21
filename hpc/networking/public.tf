resource "aws_subnet" "public" {
  vpc_id            = var.obp_vpc_id
  availability_zone = "${var.aws_region}a"
  count             = var.create_jumphost ? 1 : 0
  cidr_block        = "172.31.1.0/24"
  tags = {
    Name = "public"
  }
}

locals {
  aws_subnet_public_id                    = one(aws_subnet.public[*].id)
  aws_route_table_gateway_rt_id           = one(aws_route_table.gateway_rt[*].id)
  aws_internet_gateway_default_gateway_id = one(aws_internet_gateway.default_gateway[*].id)
}

resource "aws_internet_gateway" "default_gateway" {
  vpc_id = data.aws_vpc.obp_vpc.id
  count  = var.create_jumphost ? 1 : 0
}

resource "aws_route_table" "gateway_rt" {
  vpc_id = var.obp_vpc_id
  count  = var.create_jumphost ? 1 : 0

  tags = {
    Name = "gateway_route"
  }
}

resource "aws_route" "internet_route" {
  destination_cidr_block = "0.0.0.0/0"
  count                  = var.create_jumphost ? 1 : 0
  gateway_id             = local.aws_internet_gateway_default_gateway_id
  route_table_id         = local.aws_route_table_gateway_rt_id
}

resource "aws_route_table_association" "internet_route_association" {
  count          = var.create_jumphost ? 1 : 0
  subnet_id      = local.aws_subnet_public_id
  route_table_id = local.aws_route_table_gateway_rt_id
}
