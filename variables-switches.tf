variable "create_ssh_bastion_vm_on_public_a_network" {
  type        = bool
  default     = true
  sensitive   = false
  description = "Create SSH bastion VM on public network in availability zone A: needed for access to HPC resources for example"
}
variable "create_ssh_bastion_vm_on_public_b_network" {
  type        = bool
  default     = false
  sensitive   = false
  description = "Create SSH bastion VM on public network in availability zone B: only needed for testing across availability zones"
}

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

variable "is_nexus_openscience_running" {
  description = "Whether OpenScience nexus should be running"
  type        = bool
  default     = true
}

variable "is_nexus_obp_running" {
  description = "Whether OBP nexus should be running"
  type        = bool
  default     = true
}
