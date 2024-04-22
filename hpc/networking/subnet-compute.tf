resource "aws_subnet" "compute" {
  vpc_id            = var.pcluster_vpc_id
  availability_zone = "${var.aws_region}${var.av_zone_suffixes[count.index % 4]}"
  count             = var.compute_subnet_count
  # .1 is public, .2 and .3 are slurm
  cidr_block = "172.32.${count.index + 4}.0/24"
  tags = {
    Name = "compute_${count.index}"
  }
}

resource "aws_route_table" "compute" {
  vpc_id = var.pcluster_vpc_id
  tags = {
    Name = "compute_route"
  }
}

locals {
  aws_subnet_compute_ids = [
    for elem in aws_subnet.compute :
    elem.id
  ]
}

resource "aws_route_table_association" "compute" {
  count          = var.compute_subnet_count
  subnet_id      = local.aws_subnet_compute_ids[count.index]
  route_table_id = aws_route_table.compute.id
}
