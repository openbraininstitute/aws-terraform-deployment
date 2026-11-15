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

variable "azure_appgw_cidr_blocks" {
  type        = list(string)
  description = "Subnets of the Azure Application Gateway (its instances and its Private Link NAT addresses; azure-terraform-deployment appgw_access_subnet_ip_range and appgw_privlink_subnet_ip_range). Calls from browsers arrive from there over the VPN. Empty where no Azure gateway is in front (sandboxes)."
  default     = []
}

variable "launch_system_aca_in_azure_cidr_block" {
  type        = string
  description = "The cidr used by the launch-system ACA executors which are deployed within azure"
}

variable "launch_system_batch_in_azure_cidr_block" {
  type        = string
  description = "The cidr used by the launch-system batch executors which are deployed within azure"
}
