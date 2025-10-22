variable "aws_region" {
  type = string
}

variable "vpc_id" {
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
