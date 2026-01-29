data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "vpc_id" {
  type = string
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the bastion host"
}
