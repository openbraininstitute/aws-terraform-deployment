variable "vpc_id" {
  type = string
}

variable "aws_region" {
  type      = string
  sensitive = false
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "nat_gateway_id" {
  type        = string
  description = "The ID of the NAT gateway that is used when routing traffic out of the AWS Network."
}

variable "public_lb_listener_https_arn" {
  type        = string
  description = "ARN of the public listener (used by the public load balancer)"
}

variable "private_lb_listener_https_arn" {
  type        = string
  description = "ARN of the private listener (used by the private load balancer)"
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "invite_link" {
  type      = string
  sensitive = false
}

variable "mail_from" {
  type      = string
  sensitive = false
}

variable "virtual_lab_manager_postgres_db" {
  type        = string
  description = "Database name used by virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_postgres_user" {
  type        = string
  description = "Postgres database username used by virtual lab manager"
  sensitive   = false
}

variable "core_subnets" {
  type = list(string)
}

variable "virtual_lab_manager_depoloyment_env" {
  type        = string
  description = "deployment env, oneOf<'dev' | 'test' | 'production'>"
  sensitive   = false
}

variable "virtual_lab_manager_nexus_delta_uri" {
  type        = string
  description = "nexus delta service url"
  sensitive   = false
}

variable "virtual_lab_manager_invite_expiration" {
  type        = string
  description = "virtual lab invite expiration in days"
  sensitive   = false
}

variable "virtual_lab_manager_mail_username" {
  type        = string
  description = "username for sending emails for invites"
  sensitive   = false
}

variable "virtual_lab_manager_mail_server" {
  type        = string
  description = "Email server that sends email for invites"
  sensitive   = false
}

variable "virtual_lab_manager_mail_port" {
  type        = string
  description = "port for the starttls connection with email server"
  sensitive   = false
}

variable "virtual_lab_manager_mail_starttls" {
  type        = string
  description = "Use STARTTLS protocol to securely send emails"
  sensitive   = false
}

variable "virtual_lab_manager_use_credentials" {
  type        = string
  description = "Use username and password for authentication when sending emails"
  sensitive   = false
}

variable "virtual_lab_manager_cors_origins" {
  type        = list(string)
  description = "Origins that are allowed to make requests to the virtual lab api through a browser"
  sensitive   = false
}

variable "virtual_lab_manager_admin_base_path" {
  type        = string
  description = "admin dashboard path template string"
  sensitive   = false
}

variable "virtual_lab_manager_deployment_namespace" {
  type        = string
  description = "deployment domain use for nexus project base path"
  sensitive   = false
}

variable "virtual_lab_manager_cross_project_resolvers" {
  type        = list(string)
  description = "cross project resolver projects for project creation"
  sensitive   = false
}

variable "log_group_name" {
  type        = string
  description = "The log name within cloudwatch"
  sensitive   = false
}

variable "ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers"
}

variable "dockerhub_access_iam_policy_arn" {
  type      = string
  sensitive = false
}

variable "dockerhub_credentials_arn" {
  type      = string
  sensitive = false
}

variable "virtual_lab_manager_base_path" {
  type        = string
  description = "The base path for the virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_docker_image_url" {
  type        = string
  description = "docker image for the virtual lab manager"
  sensitive   = false
}

variable "keycloak_server_url" {
  description = "URL of the Keycloak server"
  type        = string
}

variable "virtual_lab_manager_secrets_arn" {
  type        = string
  description = "The ARN of the virtual lab manager secrets"
  sensitive   = false
}

