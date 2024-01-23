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
variable "create_nat_gateway" {
  type        = bool
  default     = true
  sensitive   = false
  description = "Create the outgoing NAT / masquerading gateway for the private subnets"
}

variable "core_webapp_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the SBO core webapp"
}

variable "cell_svc_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the SBO sonata-cell-position service"
}

variable "nexus_app_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for delta app"
}

variable "nexus_storage_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for Nexus Storage Service"
}

variable "nexus_fusion_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for nexus fusion"
}

variable "blazegraph_ecs_number_of_containers" {
  type      = number
  default   = 1
  sensitive = false
}

variable "create_nexus_elasticsearch" {
  type      = bool
  default   = true
  sensitive = false
}

variable "create_nexus_database" {
  type      = bool
  default   = true
  sensitive = false
}

variable "embedder_ecs_number_of_containers" {
  type        = number
  default     = 0
  sensitive   = false
  description = "Number of containers for the embedder app"
}

variable "create_ml_opensearch" {
  type      = bool
  default   = true
  sensitive = false
}

variable "viz_brayns_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the Brayns renderer service"
}

variable "workflow_ecs_number_of_containers" {
  type        = number
  default     = 0
  sensitive   = false
  description = "Number of containers for BBP-Workflow"
}
