variable "core_webapp_log_group_name" {
  default     = "core_webapp"
  type        = string
  description = "The log name within cloudwatch for the core webapp"
  sensitive   = false
}
variable "vpc_id" {
  type        = string
  sensitive   = false
  description = "ID of the VPC"
}
variable "core_webapp_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the SBO core webapp"
}
# TODO: delete after migration to the production domain.
variable "core_webapp_poc_hostname" {
  default     = "sbo-core-webapp.shapes-registry.org"
  type        = string
  description = "The hostname for the core webapp poc"
  sensitive   = false
}
variable "domain_zone_id" {
  type        = string
  description = "zone id of the domain where the poc hostname should be added"
  sensitive   = false
}
variable "public_alb_https_listener_arn" {
  type        = string
  description = "alb listener to which the https listener rule should be added"
  sensitive   = false
}
variable "public_alb_dns_name" {
  type        = string
  description = "public hostname of the alb, which the poc hostname should be an alias of"
  sensitive   = false
}
variable "aws_region" {
  type      = string
  sensitive = false
}
variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}
variable "core_webapp_docker_image_url" {
  type        = string
  description = "docker image for the core webapp"
  sensitive   = false
}
variable "dockerhub_access_iam_policy_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}
variable "core_webapp_hostname" {
  type        = string
  description = "The hostname for the core webapp"
  sensitive   = false
}

# TODO: update to "/app/core" after migration to the production domain.
variable "core_webapp_base_path" {
  type        = string
  description = "The base path for the core webapp"
  sensitive   = false
}

variable "epfl_cidr" {
  type        = string
  description = "CIDR of the network range used by EPFL"
  sensitive   = false
}

variable "bbp_dmz_cidr" {
  type        = string
  description = "CIDR of the BBP DMZ, containing bbpproxy, bbpssh bastion host and the proxy for SauceLabs"
  sensitive   = false
}

variable "route_table_id" {
  type        = string
  description = "route table for private networks"
  sensitive   = false
}