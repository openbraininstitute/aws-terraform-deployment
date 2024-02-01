# TODO This is only temporary to get rid of the vpc_cidr variable at nexus root level
# TODO Remove this once the storage service is using the correct subnet and security group from the networking module
# TODO Only the networking module should need the VPC ID
data "aws_vpc" "provided_vpc" {
  id = var.vpc_id
}