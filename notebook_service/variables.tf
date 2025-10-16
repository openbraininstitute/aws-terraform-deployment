variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_alb_listener_arn" {
  type = string
}

variable "alb_listener_rule_priority" {
  type = number
}

variable "base_path" {
  description = "Base path for the API"
  type        = string
}

variable "docker_image_url" {
  description = "Docker image for the notebook service"
  type        = string
}

variable "keycloak_url" {
  description = "URL of the Keycloak server, including the realm"
  type        = string
}

variable "environment" {
  description = "Environment: either staging or production"
  type        = string
}

variable "debug" {
  description = "Debug flag"
  type        = string
  default     = "false"
}

variable "internet_access_route_id" {
  type = string
}

variable "accounting_base_url" {
  type        = string
  description = "Accounting service base URL"
  sensitive   = false
}

variable "task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS task (number or string format)"
}

variable "ecs_cidr_block_a" {
  type        = string
  description = "CIDR block for ECS subnet a"
}

variable "ecs_cidr_block_b" {
  type        = string
  description = "CIDR block for ECS subnet b"
}

variable "hub_on_eks_full_url" {
  description = "Full url to reach /hub on the EKS cluster"
  type        = string
}

variable "accounting_enabled" {
  description = "Is accounting (credits required or not) enabled or not"
  type        = bool
}

variable "kubernetes_thread_enabled" {
  description = "Start a thread which regularly checks the pods in k8s"
  type        = bool
}

variable "secrets_arn" {
  description = "Secrets ARN for the notebook service"
  type        = string
}

variable "cors_allowed_origins" {
  description = "comma separated list with the list of allowed origins for the CORS settings"
  type        = string
}

variable "notebook_service_bucket_name" {
  type = string
}

variable "acounting_db_athena_connector_name" {
  type        = string
  description = "Name of the data catalog / connector of the accounting database in Athena"
}