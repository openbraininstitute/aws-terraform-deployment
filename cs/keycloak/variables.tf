data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "domain_name" {
  type      = string
  sensitive = false
}

variable "vpc_id" {
  type = string
}

variable "keycloak_allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "keycloak_subnets" {
  type = list(string)
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

variable "keycloak_admin_hostname" {
  type        = string
  description = "Hostname for the Keycloak admin console, as defined in aws-terraform-deployment-common"
  sensitive   = false
}

variable "keycloak_admin_cert_arn" {
  type        = string
  description = "ARN of the TLS certificate for the keycloak-admin subdomain"
  sensitive   = false
}

variable "cell_a_private_zone_id" {
  type        = string
  description = "Route53 private zone ID for the cell-a domain (used within the VPC)"
  sensitive   = false
}

variable "keycloak_admin_allowed_source_ip_cidr_blocks" {
  type        = list(string)
  description = "CIDRs allowed to access the Keycloak admin console"
}

variable "keycloak_ecs_cluster_name" {
  type = string
}

variable "keycloak_ecs_service_name" {
  type = string
}

variable "keycloak_task_size" {
  type = object({
    cpu    = number
    memory = number
  })

  description = "CPU and memory limit for Keycloak's ECS task (number or string format)"
}
