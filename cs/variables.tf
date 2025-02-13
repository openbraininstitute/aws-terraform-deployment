data "aws_region" "current" {}

variable "vpc_id" {
  type = string
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "aws_coreservices_ssh_key_id" {
  type = string
}

variable "private_alb_https_listener_arn" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "preferred_hostname" {
  type        = string
  description = "preferred hostname to which requests for /auth should be redirected if the host is any of the redirect_hostnames"
  sensitive   = false
}

variable "redirect_hostnames" {
  type        = list(string)
  description = "hostnames which should be redirected to the preferred hostname if there's a request for /auth"
  sensitive   = false
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
