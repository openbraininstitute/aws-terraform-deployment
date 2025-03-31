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

variable "hpc_resource_provisioner_container_version" {
  type = string
}

variable "sbo_nexusdata_bucket" {
  type = string
}

variable "containers_bucket" {
  type = string
}

variable "scratch_bucket" {
  type = string
}

variable "aws_security_group_efa_id" {
  type = string
}
