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
