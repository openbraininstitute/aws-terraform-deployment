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

variable "public_alb_listener" {
  type = string
}

variable "primary_auth_hostname" {
  type = string
}
variable "secondary_auth_hostname" {
  type = string
}

variable "epfl_cidr" {
  type = string
}

variable "bbpproxy_cidr" {
  type = string
}
