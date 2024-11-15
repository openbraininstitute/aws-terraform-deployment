variable "hpc_resource_provisioner_role" {
  type = string
}

variable "hpc_resource_provisioner_subnet_ids" {
  type = list(string)
}

variable "hpc_resource_provisioner_sg_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}
