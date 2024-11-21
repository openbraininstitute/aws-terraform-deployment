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
  default     = "bluebrain/obp-accounting-service:2024.8.8-prod"
}

variable "dockerhub_credentials_arn" {
  description = "ARN of the secret containing the DockerHub credentials"
  type        = string
}

variable "dockerhub_access_iam_policy_arn" {
  description = "ARN of IAM policy to access the secret containing the DockerHub credentials"
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
