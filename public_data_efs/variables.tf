variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "access_point_subnet_ids" {
  type = list(string)
}

variable "entitycore_open_data_bucket" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}
