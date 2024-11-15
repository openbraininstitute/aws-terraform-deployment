variable "pcluster_vpc_id" {
  type        = string
  description = "ID of the VPC created in the VPC module"
}

variable "obp_vpc_id" {
  type        = string
  description = "ID of the OBP VPC"
}

variable "slurm_db_a_subnet_id" {
  type = string
}

variable "create_compute_instances" {
  type = bool
}

variable "create_jumphost" {
  type = bool
}

variable "create_slurmdb" {
  type = bool
}

variable "account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_endpoints_subnet_cidr" {
  type = string
}
