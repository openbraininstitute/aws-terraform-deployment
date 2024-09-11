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
  default     = "https://openbluebrain.com/api/nexus/v1"
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

variable "virtual_lab_manager_mail_username" {
  default     = "AKIAZYSNA64ZRY6UDRMA"
  type        = string
  description = "username for sending emails for invites"
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

variable "virtual_lab_manager_cors_origins" {
  type        = list(string)
  default     = ["http://localhost:3000"]
  description = "Origins that are allowed to make requests to the virtual lab api through a browser"
  sensitive   = false
}

variable "virtual_lab_manager_admin_base_path" {
  default     = "{}/mmb-beta/virtual-lab/lab/{}/admin?panel=billing"
  type        = string
  description = "admint dashboard path template string"
  sensitive   = false
}

variable "virtual_lab_manager_deployment_namespace" {
  default     = "https://openbluebrain.com"
  type        = string
  description = "deployment domain use for nexus project base path"
  sensitive   = false
}

variable "virtual_lab_manager_cross_project_resolvers" {
  default     = ["public/ephys", "public/thalamus", "public/ngv", "public/multi-vesicular-release", "public/hippocampus", "public/topological-sampling", "bbp/lnmce", "public/ngv-anatomy", "bbp-external/seu", "public/forge", "public/sscx", "bbp/mouselight", "public/morphologies", "neurosciencegraph/datamodels", "bbp/mmb-point-neuron-framework-model", "neurosciencegraph/data"]
  type        = list(string)
  description = "cross project resolver projects for project creation"
  sensitive   = false
}
