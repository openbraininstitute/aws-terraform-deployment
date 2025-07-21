variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_listener_arn" {
  type = string
}

variable "alb_listener_rule_priority" {
  type = number
}

variable "base_path" {
  description = "Base path for the API"
  type        = string
}

variable "cors_origins" {
  description = "CORS origins"
  type        = list(string)
}

variable "api_docker_image_url" {
  description = "Docker image for the API service"
  type        = string
}

variable "worker_docker_image_url" {
  description = "Docker image for the worker service"
  type        = string
}

variable "deployment_env" {
  description = "Environment in which the service is deployed"
  type        = string
  default     = "production"
}

variable "keycloak_server_url" {
  description = "URL of the Keycloak server"
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

variable "secrets_arn" {
  type = string
}

variable "nexus_delta_uri" {
  type = string
}

variable "accounting_base_url" {
  type        = string
  description = "Accounting service base URL"
  sensitive   = false
}

variable "entitycore_url" {
  description = "entitycore URL"
  type        = string
}

# TODO : Configure task sizes for api, consider adding autoscaling params for workers

variable "worker_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS worker task (number or string format)"
}

variable "api_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS API task (number or string format)"
}

variable "num_workers" {
  type = string

  description = "Number of worker processes per each ECS worker node"
}

variable "worker_autoscaler_min_capacity" {
  type = number

  description = "Minimum number of worker nodes requested from capacity provider"
}

variable "worker_capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string # Valid values: FARGATE, FARGATE_SPOT
    weight            = number
  }))

  description = "Capacity provider strategy for worker service"
}
