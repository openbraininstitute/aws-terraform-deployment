variable "postgres_host" {
  type = string
}

variable "postgres_database" {
  type = string
}

variable "postgres_username" {
  type = string
}

variable "target_base_uri" {
  type        = string
  description = "The base uri to patch content urls in distributions"
}

variable "target_bucket" {
  type        = string
  description = "The destination bucket for physical files"
}

variable "dockerhub_credentials_arn" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent"
}

variable "nexus_secrets_arn" {
  type        = string
  description = "The ARN of the secrets manager secret that contains the nexus secrets"
}

variable "target_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket that the ship will copy data to"
}

variable "second_target_bucket_arn" {
  type        = string
  description = "The ARN of the second S3 bucket that the ship will copy data to"
}

variable "aws_region" {
  type        = string
  description = "The AWS region in which the resources will be created."
}
