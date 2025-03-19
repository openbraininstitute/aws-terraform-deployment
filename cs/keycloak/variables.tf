data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "vpc_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "efs_mt_subnets" {
  type = list(string)
}

variable "preferred_hostname" {
  type        = string
  description = "preferred hostname to which requests for /auth should be redirected if the host is any of the redirect_hostnames"
  sensitive   = false
}

variable "private_alb_https_listener_arn" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "keycloak_management_port" {
  type = number
}

variable "keycloak_port" {
  type = number
}

# This is the subnet where ECS service will be running
variable "private_subnets" {
  type = list(string)
}

variable "keycloak_secrets_arn" {
  type        = string
  description = "ARN of the Keycloak secrets manager"
  sensitive   = false
}

variable "keycloak_task_size" {
  type = object({
    cpu    = number
    memory = number
  })

  description = "CPU and memory limit for Keycloak's ECS task (number or string format)"
}
