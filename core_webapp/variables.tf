variable "key" {
  type        = string
  description = "Unique key for the module instance, used as a suffix for resource names"
  sensitive   = false
}

variable "hostname" {
  default     = null
  type        = string
  description = "Hostname for the core webapp"
  sensitive   = false
}

variable "log_group_name" {
  type        = string
  description = "The log name within cloudwatch for the core webapp"
  sensitive   = false
}

variable "vpc_id" {
  type        = string
  sensitive   = false
  description = "ID of the VPC"
}

variable "ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the SBO core webapp"
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB listener to which the listener rule should be added"
  sensitive   = false
}

variable "alb_listener_rule_priority" {
  type        = number
  description = "Priority of the ALB listener rule"
  sensitive   = false
}

variable "aws_region" {
  type      = string
  sensitive = false
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "docker_image_url" {
  type        = string
  description = "Docker image for the core webapp"
  sensitive   = false
}

variable "route_table_id" {
  type        = string
  description = "Route table for private networks"
  sensitive   = false
}

variable "allowed_source_ip_cidr_blocks" {
  default     = null
  type        = list(string)
  description = "List of CIDR blocks to allow access to the webapp"
}

variable "secrets_arn" {
  type        = string
  description = "Secrets ARN"
  sensitive   = false
}

variable "accounting_base_url" {
  type        = string
  description = "Accounting service base URL"
  sensitive   = false
}

variable "env_NEXTAUTH_URL" {
  type        = string
  sensitive   = false
  description = "NEXTAUTH_URL environment value for the webapp"
}

variable "env_KEYCLOAK_ISSUER" {
  type        = string
  sensitive   = false
  description = "KEYCLOAK_ISSUER environment value for the webapp"
}

variable "env_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY" {
  type        = string
  sensitive   = false
  description = "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY environment value for the webapp"
}

variable "env_NEXT_PUBLIC_BBS_ML_PRIVATE_BASE_URL" {
  type        = string
  sensitive   = false
  description = "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY environment value for the webapp"
}

variable "env_NEXT_PUBLIC_DEPLOYMENT_ENV" {
  type        = string
  description = "env core-web-app is deployed <staging|production>"
  sensitive   = false
}

variable "env_NEXT_PUBLIC_MATOMO_URL" {
  type        = string
  description = "Matomo url to server analytics script, (this is global)"
  sensitive   = false
}

variable "env_NEXT_PUBLIC_MATOMO_CDN_URL" {
  type        = string
  description = "Matomo url to server analytics script using cdn, (this is global)"
  sensitive   = false
}

variable "env_NEXT_PUBLIC_MATOMO_SITE_ID" {
  type        = string
  description = "Matomo site id <staging | production>"
  sensitive   = false
}
