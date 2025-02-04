data "aws_region" "current" {}

variable "vpc_id" {
  type = string
}

variable "route_table_private_subnets_id" {
  type = string
}
