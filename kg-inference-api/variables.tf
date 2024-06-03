# [data.terraform_remote_state.common.outputs.public_alb_dns_name]
# data.terraform_remote_state.common.outputs.domain_zone_id
# data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
# data.terraform_remote_state.common.outputs.route_table_private_subnets_id
# data.terraform_remote_state.common.outputs.vpc_cidr_block
# data.terraform_remote_state.common.outputs.vpc_id

# aws_region
# epfl_cidr
# kg_inference_api_docker_image_url
# kg_inference_api_hostname
# kg_inference_api_log_group_name

variable "aws_region" {
  type      = string
  sensitive = false
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
variable "route_table_id" {
  type        = string
  description = "route table for private networks"
  sensitive   = false
}
variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}
variable "vpc_id" {
  type        = string
  sensitive   = false
  description = "ID of the VPC"
}
variable "epfl_cidr" {
  sensitive = false
  type      = string
}

variable "kg_inference_api_docker_image_url" {
  # default     = "bluebrain/kg-inference-api:latest"
  type        = string
  description = "docker image for the KG Inference API"
  sensitive   = false
}

variable "kg_inference_api_hostname" {
  # default     = "kg-inference-api.shapes-registry.org"
  type        = string
  description = "The hostname for the KG Inference API"
  sensitive   = false
}

variable "kg_inference_api_log_group_name" {
  # default     = "kg_inference_api"
  type        = string
  description = "The log name within cloudwatch for the kg inference api"
  sensitive   = false
}
variable "dockerhub_access_iam_policy_arn" {
  type      = string
  sensitive = false
}
variable "dockerhub_credentials_arn" {
  type      = string
  sensitive = false
}