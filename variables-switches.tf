variable "virtual_lab_manager_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the virtual lab manager"
}

variable "deployment_env" {
  type        = string
  description = "The deployment environment, values: 'staging', 'production', 'sandbox-hpc', 'sandbox-nse', 'sandbox-benchmarks'"
}

variable "core_web_app_in_azure_cidr_block" {
  type        = string
  description = "The cidr used by the corewebapp containers which are deployed within azure"
}

variable "launch_system_aca_in_azure_cidr_block" {
  type        = string
  description = "The cidr used by the launch-system ACA executors which are deployed within azure"
}

variable "launch_system_batch_in_azure_cidr_block" {
  type        = string
  description = "The cidr used by the launch-system batch executors which are deployed within azure"
}
