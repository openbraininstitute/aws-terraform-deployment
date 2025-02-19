variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS Cluster Name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS Service Name"
  type        = string
}

variable "ecs_task_definition_name" {
  description = "ECS Task Definition Name"
  type        = string
}

variable "github_organisation" {
  description = "GitHub Organization or User"
  type        = string
}

variable "repo_name" {
  description = "GitHub Repository Name"
  type        = string
}
