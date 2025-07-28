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

variable "keycloak_server_url" {
  description = "URL of the Keycloak server"
  type        = string
}

variable "keycloak_realm_name" {
  description = "Keycloak realm name"
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

variable "secret_recovery_window_in_days" {
  description = "Secret recovery window in days"
  type        = number
}
