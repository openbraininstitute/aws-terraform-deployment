variable "aws_region" {
  type = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "vpc_id" {
  type    = string
  default = ""
}
variable "nat_gateway_id" {
  type    = string
  default = ""
}
variable "secret_dockerhub_arn" {
  type    = string
  default = ""
}

variable "scientific_data_bucket_name" {
  type = string
}

variable "dockerhub_access_iam_policy_arn" {
  type    = string
  default = ""
}

variable "route_table_private_subnets_id" {
  type    = string
  default = ""
}

variable "private_alb_listener_arn" {
  type = string
}

variable "epfl_cidr" {
  type        = string
  default     = "128.178.0.0/15"
  description = "CIDR of the network range used by EPFL"
  sensitive   = false
}

variable "viz_enable_sandbox" {
  default     = false
  type        = bool
  description = "To create a sandbox or not to create a sandbox"
  sensitive   = false
}

### VIZ Brayns renderer service ###

variable "viz_brayns_log_group_name" {
  default     = "viz_brayns"
  type        = string
  description = "The log name within cloudwatch for Brayns"
  sensitive   = false
}

variable "viz_brayns_docker_image_url" {
  type        = string
  default     = "ppx86/brayns_aws_wrapper:latest"
  description = "Docker image for Brayns renderer service"
  sensitive   = false
}

## VIZ PostgreSQL ###


variable "viz_postgresql_database_name" {
  type      = string
  default   = "vsm"
  sensitive = false
}

variable "viz_postgresql_database_username" {
  type      = string
  default   = "vsm"
  sensitive = false
}

variable "aws_security_group_nlb_id" {
  type      = string
  sensitive = false
  default   = ""
}

# VIZ VSM

variable "viz_vsm_log_group_name" {
  default     = "viz_vsm"
  type        = string
  description = "The log name within cloudwatch for VSM"
  sensitive   = false
}

variable "viz_vsm_proxy_log_group_name" {
  default     = "viz_vsm_proxy"
  type        = string
  description = "The log name within cloudwatch for VSM-Proxy"
  sensitive   = false
}

variable "vsm_base_path" {
  default     = "/vsm/master"
  type        = string
  description = "Basepath at which VSM container can be reached via the ALB"
  sensitive   = false
}

variable "vsm_proxy_base_path" {
  default     = "/vsm/proxy"
  type        = string
  description = "Basepath  at which VSM container can be reached via the ALB"
  sensitive   = false
}

variable "viz_vsm_docker_image_url" {
  type        = string
  default     = "bluebrain/vsm:latest"
  description = "Docker image for VSM services"
  sensitive   = false
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = { SBO_Billing = "viz" }
}

variable "readonly_access_policy_statement_part1" {
  description = "Policy for read-only permission pt1"
  type        = string
}

variable "readonly_access_policy_statement_part2" {
  description = "Policy for read-only permission pt2"
  type        = string
}

variable "aws_ssoadmin_instances_arns" {
  description = "ARN of the ssoadmin instances"
  type        = list(string)
}

variable "is_production" {
  type = bool
}
