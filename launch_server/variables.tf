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
  default     = "985539765147.dkr.ecr.us-east-1.amazonaws.com/launch-system:latest-dev"
}

variable "executor_image_url" {
  description = "Image for the launch service executor container"
  type        = string
  default     = "985539765147.dkr.ecr.us-east-1.amazonaws.com/launch-executor:latest"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
}

variable "az_region" {
  description = "region in Azure"
  type        = string
}

variable "internet_access_route_id" {
  type = string
}

variable "secrets_arn" {
  # Need the following secrets:
  # DB_PASS
  # AZURE_CLIENT_SECRET
  # AZURE_CLIENT_ID
  # AZURE_TENANT_ID
  # AZ_SUBSCRIPTION_ID
  # AZ_BATCH_ACCOUNT_NAME
  # AZ_BATCH_POOL_NAME
  # AZ_UPLOAD_BLOB_SAS_URL

  type = string
}

variable "obi_backup_plan" {
  description = "Name of the OBI backup plan"
  type        = string
}


variable "keycloak_client_id" {
  description = "ID for refreshing offline_token in keycloak"
  type        = string
  default     = "obi-entitysdk-auth"
}

variable "token_lifetime_extension_interval" {
  type = string
}

variable "simulation_launch_command" {
  description = "Base command launched within Azure Batch"
  type        = string
  default     = "/nfs/public/test-run-sim/run-simulation.py"
}

variable "entitycore_url" {
  description = "URL of entitycore"
  type        = string
}

variable "launch_server_url" {
  description = "URL of this server"
  type        = string
}
