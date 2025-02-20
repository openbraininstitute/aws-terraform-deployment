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
  default     = "https://openbluebrain.com/auth/realms/SBO/"
}

variable "image_url" {
  description = "Image for the entitycore service"
  type        = string
  default     = "public.ecr.aws/openbraininstitute/entitycore:2025.2.0-prod"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "entitycore"
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
  default     = "entitycore"
}

variable "internet_access_route_id" {
  type = string
}

variable "entitycore_service_secrets_arn" {
  type = string
}
