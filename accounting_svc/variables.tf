variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "alb_listener_arn" {
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

variable "secrets_arn" {
  description = "ARN of the secret containing secrets for accounting service"
  type        = string
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:accounting_db-SJGtMG"
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
