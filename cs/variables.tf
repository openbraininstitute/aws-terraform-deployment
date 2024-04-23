variable "vpc_id" {
  type = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "route_table_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}
