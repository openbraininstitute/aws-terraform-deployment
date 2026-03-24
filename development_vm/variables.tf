data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}

variable "ami_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the VM"
}

variable "instance_volume_size" {
  type        = number
  description = "Size of the root volume in GB for the VM"
}

variable "vm_name" {
  type        = string
  description = "Name of the VM"
}

variable "subnet_cidr_block" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "user_groups" {
  type = map(object({
    users = list(object({
      username   = string
      email      = string
      public_key = string
    }))
    sudo_access = bool
  }))
}
