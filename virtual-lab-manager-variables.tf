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

variable "virtual_lab_manager_depoloyment_env" {
  default     = "production"
  type        = string
  description = "deployment env, oneOf<'dev' | 'test' | 'production'>"
  sensitive   = false
}

variable "virtual_lab_manager_nexus_delta_uri" {
  default     = "https://sbo-nexus-delta.shapes-registry.org/v1"
  type        = string
  description = "nexus delta service url"
  sensitive   = false
}

variable "virtual_lab_manager_invite_expiration" {
  default     = "7"
  type        = string
  description = "virtual lab invite expiration in days"
  sensitive   = false
}

variable "virtual_lab_manager_invite_link" {
  default     = "https://openbrainplatform.org"
  type        = string
  description = "virtual lab invite url (frontend domain) without the base path as '/mmb-beta'"
  sensitive   = false
}
