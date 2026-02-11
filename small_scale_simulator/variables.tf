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

variable "cors_origin_regex" {
  description = "CORS origin regex"
  type        = string
  default     = null
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

variable "tags" {
  description = "Tags"
  default     = { SBO_Billing = "small_scale_simulator" }
  type        = map(string)
}

# TODO : Configure task sizes for api

variable "api_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS API task (number or string format)"
}

variable "daemon_workers" {
  type = map(object({
    task_size = object({
      cpu    = any
      memory = any
    })
    num_workers_per_task = number
    queues               = list(string)
    num_worker_tasks     = optional(number, 1)
    autoscaler = optional(object({
      enabled              = optional(bool, false)
      max_num_worker_tasks = optional(number, 10)
    }), {})
    capacity_provider_strategy = list(object({
      capacity_provider = string # Valid values: FARGATE, FARGATE_SPOT
      weight            = number
    }))
  }))

  description = "Map of daemon worker configurations. Each key represents a persistent worker service name with optional auto-scaling configuration."
  default     = {}
}

variable "batch_workers" {
  type = map(object({
    task_size = object({
      cpu    = any
      memory = any
    })
    num_workers_per_task = number
    queues               = list(string)
    max_worker_tasks     = number
    capacity_provider    = string # Valid values: FARGATE, FARGATE_SPOT
  }))

  description = "Map of batch worker configurations. Each key represents an on-demand worker auto-provisioned based on CloudWatch job queue length metrics."
  default     = {}
}
