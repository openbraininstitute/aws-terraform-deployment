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

variable "accounting_base_url" {
  type        = string
  description = "Accounting service base URL"
  sensitive   = false
}

variable "entitycore_url" {
  description = "entitycore URL"
  type        = string
}

# TODO : Configure task sizes for api

variable "api_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS API task (number or string format)"
}

variable "workers" {
  type = map(object({
    task_size = object({
      cpu    = any
      memory = any
    })
    num_workers             = number
    queues                  = string
    autoscaler_min_capacity = number
    capacity_provider_strategy = list(object({
      capacity_provider = string # Valid values: FARGATE, FARGATE_SPOT
      weight            = number
    }))
  }))

  description = "Map of worker configurations. Each key represents a worker service name with its configuration."
}

variable "on_demand_workers" {
  type = map(object({
    task_size = object({
      cpu    = any
      memory = any
    })
    num_workers       = number
    queues            = list(string)
    max_workers       = number
    capacity_provider = string # Valid values: FARGATE, FARGATE_SPOT
  }))

  description = "Map of on-demand worker configurations. Each worker type monitors specified queues and scales based on CloudWatch job queue length metrics."
  default     = {}
}
