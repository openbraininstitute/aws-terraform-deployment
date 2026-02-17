variable "virtual_lab_manager_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the virtual lab manager"
}

variable "is_production" {
  type        = bool
  default     = true
  sensitive   = false
  description = "Whether deployment is happening in production or not"
}

variable "is_staging" {
  description = "Whether deployment is happening in staging"
  type        = bool
  default     = false
}

variable "deployment_env" {
  type        = string
  description = "The deployment environment, values: 'staging', 'production'"
}

variable "core_web_app_in_azure_cidr_block" {
  type        = string
  description = "The cidr used by the corewebapp containers which are deployed within azure"
}
