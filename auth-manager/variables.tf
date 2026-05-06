variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "route_table_id" {
  type = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
}

variable "obi_backup_plan" {
  description = "Name of the OBI backup plan"
  type        = string
}

variable "auth_manager_secrets_arn" {
  type = string
}

variable "image_url" {
  description = "Image for the AuthManager service"
  type        = string
}

variable "root_path" {
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

variable "private_alb_listener_arn" {
  type = string
}

variable "auth_manager_svc_tags" {
  description = "tags of the resources."
  type        = map(string)
  default     = { SBO_Billing = "auth_manager_svc" }
}

variable "primary_domain" {
  type = string
}

variable "client_redirect_domain" {
  type        = string
  description = "Domain where users are redirected after granting offline token consent"
}

variable "keycloak_client_uuid" {
  type = string
}

variable "ack_state_expiry" {
  type    = number
  default = 60
}

variable "keycloak_client_id" {
  type = string
}

variable "deployment_env" {
  description = "Deployment environment (e.g. staging, production)"
  type        = string
}

variable "number_of_containers" {
  type    = number
  default = 1
}

variable "keycloak_server_url" {
  type = string
}
