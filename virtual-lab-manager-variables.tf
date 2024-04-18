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

variable "virtual_lab_manager_mail_username" {
  default     = "AKIAZYSNA64ZRY6UDRMA"
  type        = string
  description = "username for sending emails for invites"
  sensitive   = false
}

variable "virtual_lab_manager_mail_from" {
  default     = "noreply@openbrainplatform.org"
  type        = string
  description = "noreply address on behalf of which the email is sent"
  sensitive   = false
}

variable "virtual_lab_manager_mail_server" {
  default     = "email-smtp.us-east-1.amazonaws.com"
  type        = string
  description = "Email server that sends email for invites"
  sensitive   = false
}

variable "virtual_lab_manager_mail_port" {
  default     = "25"
  type        = string
  description = "port for the starttls connection with email server"
  sensitive   = false
}

variable "virtual_lab_manager_mail_starttls" {
  default     = "True"
  type        = string
  description = "Use STARTTLS protocol to securely send emails"
  sensitive   = false
}

variable "virtual_lab_manager_use_credentials" {
  default     = "True"
  type        = string
  description = "Use username and password for authentication when sending emails"
  sensitive   = false
}
