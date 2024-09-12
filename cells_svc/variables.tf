variable "cell_svc_log_group_name" {
  default     = "cell_svc"
  type        = string
  description = "The log name within cloudwatch for the cell svc"
  sensitive   = false
}

variable "cell_svc_docker_image_url" {
  default     = "bluebrain/obp-sonata-cell-position:2024.9.1"
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

variable "public_alb_https_listener_arn" {
  type = string
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
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

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "tags" {
  description = "Tags"
  default     = { SBO_Billing = "cell_svc" }
  type        = map(string)
}
