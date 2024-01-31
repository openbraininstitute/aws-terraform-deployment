variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "nat_gateway_id" {
  type    = string
  default = ""
}
