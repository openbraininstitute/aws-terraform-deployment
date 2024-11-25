
variable "aws_region" {
  type = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "obp_vpc_id" {
  type = string
}

variable "obp_vpc_default_sg_id" {
  type = string
}

variable "sbo_billing" {
  type = string
}

variable "slurm_mysql_admin_username" {
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

variable "lambda_subnet_cidr" {
  description = "CIDR for the subnet in which lambdas can be deployed"
  type        = string
}

variable "is_production" {
  type        = bool
  default     = true
  sensitive   = false
  description = "Whether deployment is happening in production or not"
}

variable "aws_endpoints_subnet_cidr" {
  type = string
}

variable "endpoints_route_table_id" {
  type        = string
  description = "ID for the route table that allows connecting to endpoints"
}

variable "hpc_slurm_secrets_arn" {
  type = string
}

variable "domain_zone_id" {
  type = string
}
