# We'd like to have each pcluster in its own subnet, but terraform is a bit stupid about this.
# The only way to get rid of the default route to the VPC subnet (ie. *EVERYTHING*) is to run
# terraform (see "importing a route" on https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table.html#adopting-an-existing-local-route),
# change your config and re-run terraform.
#
# Since that's not how we want to do this, we'll create some NACLs to block the compute subnets
# from talking to each other.
# see acl.tf
#
# There's an open issue about this on github: https://github.com/hashicorp/terraform-provider-aws/issues/33117
#
# In order for the compute clusters to be able to talk to the endpoints, we'll put those in their own dedicated subnet as well

resource "aws_subnet" "compute_endpoints" {
  vpc_id            = var.pcluster_vpc_id
  availability_zone = "${var.aws_region}${var.av_zone_suffixes[count.index % length(var.av_zone_suffixes)]}"
  count             = length(var.av_zone_suffixes)
  cidr_block        = "172.32.4.0/24"
  tags = {
    Name = "compute_endpoints_${var.av_zone_suffixes[count.index % length(var.av_zone_suffixes)]}"
  }
}

resource "aws_subnet" "compute_efs" {
  vpc_id            = var.pcluster_vpc_id
  availability_zone = "${var.aws_region}${var.av_zone_suffixes[count.index % length(var.av_zone_suffixes)]}"
  count             = length(var.av_zone_suffixes)
  cidr_block        = "172.32.5.0/24"
  tags = {
    Name = "compute_efs_${var.av_zone_suffixes[count.index % length(var.av_zone_suffixes)]}"
  }
}

resource "aws_subnet" "compute" {
  vpc_id            = var.pcluster_vpc_id
  availability_zone = "${var.aws_region}${var.av_zone_suffixes[count.index % length(var.av_zone_suffixes)]}"
  count             = var.compute_subnet_count
  # .1 is public, .2 and .3 are slurm, .4 is compute_endpoints, .5 is efs
  cidr_block = "172.32.${count.index + 6}.0/24"
  tags = {
    Name = "compute_${count.index}"
  }
}

resource "aws_route_table" "compute" {
  vpc_id = var.pcluster_vpc_id
  count  = var.compute_subnet_count

  tags = {
    Name = "compute_route_${count.index}"
  }
}

#resource "aws_route" "compute" {
#  route_table_id = aws_route_table.compute[count.index].id
#
#  count                  = var.compute_subnet_count
#  destination_cidr_block = "172.32.${count.index + 4}.0/24"
#  gateway_id             = "local"
#}

locals {
  aws_subnet_compute_ids = [
    for elem in aws_subnet.compute :
    elem.id
  ]
  aws_subnet_compute_endpoints_ids = [
    for elem in aws_subnet.compute_endpoints :
    elem.id
  ]
  aws_subnet_compute_efs_ids = [
    for elem in aws_subnet.compute_efs :
    elem.id
  ]
}

resource "aws_route_table_association" "compute" {
  count          = var.compute_subnet_count
  subnet_id      = aws_subnet.compute[count.index].id
  route_table_id = aws_route_table.compute[count.index].id
}
