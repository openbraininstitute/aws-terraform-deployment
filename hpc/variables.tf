
variable "aws_region" {
  type = string
}

variable "obp_vpc_id" {
  type = string
}

variable "sbo_billing" {
  type = string
}

variable "slurm_mysql_admin_username" {
  type = string
}

variable "slurm_mysql_admin_password" {
  type = string
}

variable "create_compute_instances" {
  type = bool
}

variable "num_compute_instances" {
  type = number
}

variable "create_slurmdb" {
  type = bool
}

variable "compute_instance_type" {
  type = string
}

variable "create_jumphost" {
  type = bool
}

variable "compute_nat_access" {
  type = bool
}

variable "compute_subnet_count" {
  type = number
}

variable "av_zone_suffixes" {
  type = list(string)
}

variable "peering_route_tables" {
  type = list(string)
}

variable "existing_route_targets" {
  type = list(string)
}
