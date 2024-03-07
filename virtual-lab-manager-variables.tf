variable "virtual_lab_manager_postgres_db" {
  default     = "vlm"
  type        = string
  description = "Database name used by virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_postgres_user" {
  default     = "vlm_user"
  type        = string
  description = "Postgres database username used by virtual lab manager"
  sensitive   = false
}
