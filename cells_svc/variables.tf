variable "cell_svc_hostname" {
  default     = "sbo-cell-svc.shapes-registry.org"
  type        = string
  description = "The hostname for the cell svc"
  sensitive   = false
}

variable "cell_svc_log_group_name" {
  default     = "cell_svc"
  type        = string
  description = "The log name within cloudwatch for the cell svc"
  sensitive   = false
}

variable "cell_svc_docker_image_url" {
  default     = "bluebrain/obp-sonata-cell-position@sha256:01d7c06b3486316b08c13f96a587282de47f92b967ced592fd8496fbea812b93"
  type        = string
  description = "docker image for the sonata-cell-service"
  sensitive   = false
}

variable "cell_svc_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the SBO sonata-cell-position service"
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "dockerhub_access_iam_policy_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}

variable "domain_zone_id" {
  type = string
}

variable "public_alb_https_listener_arn" {
  type = string
}

variable "public_alb_dns_name" {
  type = string
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "aws_coreservices_ssh_key_id" {
  type = string
}

variable "amazon_linux_ecs_ami_id" {
  type = string
}

variable "epfl_cidr" {
  type = string
}
