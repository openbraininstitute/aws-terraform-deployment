variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "private_alb_listener_arn" {
  type = string
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
}

variable "cors_origins" {
  description = "CORS origins"
  type        = list(string)
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "image_url" {
  description = "Image for the launch service"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
}

variable "az_subscription_id" {
  description = "Subscription ID in Azure"
  type        = string
}

variable "azure_client_id" {
  description = "client ID in Azure, used for authentication"
  type        = string
}

variable "azure_client_secret_arn" {
  description = "client secret to go with client ID in Azure, used for authentication"
  type        = string
}

variable "azure_tenant_id" {
  description = "tenent id in Azure"
  type        = string
}

variable "az_batch_account_name" {
  description = "name of batch account in Azure"
  type        = string
}

variable "az_region" {
  description = "region in Azure"
  type        = string
}

variable "az_batch_pool_name" {
  description = "batch pool name in Azure"
  type        = string
}

variable "internet_access_route_id" {
  type = string
}

variable "launch_service_secrets_arn" {
  type = string
}

variable "obi_backup_plan" {
  description = "Name of the OBI backup plan"
  type        = string
}


variable "keycloak_client_id" {
  description = "ID for refreshing offline_token in keycloak"
  type = string
}

variable "keycloak_client_secret_arn" {
  description = "arn for secret for ID for refreshing offline_token in keycloak"
  type        = string
}

variable "token_lifetime_extension_interval" {
  type = string
}

variable "token_lifetime_extension_url" {
  type = string

  #TOKEN_LIFETIME_EXTENSION_URL: str = "http://example.openbraininstitute.org/auth/realms/SBO/protocol/openid-connect/userinfo"
}

variable "entitycore_url" {
  type = string
}

variable "launch_server_url" {
  type = string
}
