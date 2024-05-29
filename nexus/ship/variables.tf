variable "postgres_host" {
  type = string
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