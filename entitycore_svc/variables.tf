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

variable "cors_origin_regex" {
  description = "CORS origin regex"
  type        = string
  default     = null
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "image_url" {
  description = "Image for the entitycore service"
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

variable "internet_access_route_id" {
  type = string
}

variable "entitycore_service_secrets_arn" {
  type = string
}

variable "aws_s3_internal_bucket" {
  description = "S3 bucket name in which entitycore data lives."
  type        = string
}

variable "aws_s3_internal_region" {
  description = "S3 region name in which entitycore data lives."
  type        = string
}

variable "aws_s3_open_bucket" {
  description = "S3 bucket name in which open data lives."
  type        = string
}

variable "aws_s3_open_region" {
  description = "S3 region name in which open data lives."
  type        = string
}

variable "s3_bucket_allowed_origins" {
  description = "Allowed origins for the S3 bucket"
  type        = list(string)
}

variable "obi_backup_plan" {
  description = "Name of the OBI backup plan"
  type        = string
}

variable "api_asset_post_max_size" {
  description = "Maximum size of file uploaded through API"
  type        = string
}

variable "pagination_default_page_size" {
  description = "Default page size for pagination in search endpoints"
  type        = string
}

variable "pagination_max_page_size" {
  description = "Maximum page size for pagination in search endpoints"
  type        = string
}

variable "db_migration_statement_timeout_ms" {
  description = "Abort any statement that takes more than the specified amount of time"
  type        = string
}

variable "db_migration_lock_timeout_ms" {
  description = "Abort any statement that waits longer than the specified amount of time"
  type        = string
}
