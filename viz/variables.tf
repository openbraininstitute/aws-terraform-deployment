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

variable "domain_zone_id" {
  type    = string
  default = ""
}

variable "alb_listener_arn" {
  type = string
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

# Created in AWS secret manager
variable "viz_vsm_db_password_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:viz_vsm_db_password-HpmfWe"
  type        = string
  description = "The ARN of the viz vsm secret"
  sensitive   = false
}

### VIZ Brayns renderer service ###

variable "viz_brayns_log_group_name" {
  default     = "viz_brayns"
  type        = string
  description = "The log name within cloudwatch for Brayns"
  sensitive   = false
}
#TODO DEL?
variable "viz_brayns_hostname" {
  default     = "private-alb-sbo-brayns.shapes-registry.org"
  type        = string
  description = "Hostname at which Brayns containers can be reached via the private ALB"
  sensitive   = false
}

variable "viz_brayns_docker_image_url" {
  type        = string
  default     = "ppx86/brayns_aws_wrapper:latest"
  description = "Docker image for Brayns renderer service"
  sensitive   = false
}

## VIZ PostgreSQL ###

variable "viz_postgresql_database_port" {
  default   = 5432
  type      = number
  sensitive = false
}

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

variable "viz_postgresql_admin_username" {
  type      = string
  default   = "admin"
  sensitive = false
}

variable "aws_security_group_alb_id" {
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

# TODO REMOVE AFTER MIGRATIONS
variable "aws_lb_alb_arn" {
  type      = string
  sensitive = false
  default   = ""
}


variable "viz_vsm_proxy_hostname" {
  default     = "sbo-vsm-proxy.shapes-registry.org"
  type        = string
  description = "Hostname at which VSM-Proxy container can be reached via the ALB"
  sensitive   = false
}

variable "viz_vsm_docker_image_url" {
  type        = string
  default     = "bluebrain/vsm:latest"
  description = "Docker image for VSM services"
  sensitive   = false
}

variable "viz_brayns_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the Brayns renderer service"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = { SBO_Billing = "viz" }
}

