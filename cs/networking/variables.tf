variable "vpc_id" {
  type = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "route_table_private_subnets_id" {
  type = string
}
