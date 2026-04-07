variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "private_alb_listener_arn" {
  type = string
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
}

variable "docker_image_url" {
  description = "Docker image for the accounting service"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "accounting"
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
  default     = "accounting"
}

variable "internet_access_route_id" {
  type = string
}

variable "accounting_service_secrets_arn" {
  type = string
}

variable "accounting_db_ro_secret_arn" {
  type        = string
  description = "ARN of the secret containing a username and password for read-only access to the database"
}

variable "aws_deployment_env" {
  type        = string
  description = "Environment in AWS for the deployment"
}