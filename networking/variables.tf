variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "route_table_id" {
  type = string
}

