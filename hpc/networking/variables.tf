variable "obp_vpc_id" {
  type        = string
  description = "ID of the existing VPC"
}

variable "pcluster_vpc_id" {
  type        = string
  description = "ID of the VPC created in the VPC module"
}

variable "vpc_peering_connection_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "create_jumphost" {
  type = bool
}

variable "create_compute_instances" {
  type = bool
}

variable "create_slurmdb" {
  type = bool
}

variable "compute_nat_access" {
  type = bool
}

variable "compute_subnet_count" {
  type = number
}

variable "av_zone_suffixes" {
  type = list(any)
}

variable "peering_route_tables" {
  type = list(string)
}

variable "existing_route_targets" {
  type = list(string)
}

variable "security_groups" {
  description = "Security groups to add to the Interface endpoints"
  type        = list(string)
}

variable "obp_vpc_default_sg_id" {
  description = "ID for the default security group in the OBP VPC"
  type        = string
}

variable "lambda_subnet_cidr" {
  description = "CIDR for the subnet in which lambdas can be deployed"
  type        = string
}

variable "existing_public_subnet_cidrs" {
  description = "Existing public subnet CIDR blocks for routing compute subnets to, if any. Mostly for debugging purposes."
  type        = list(string)
}
