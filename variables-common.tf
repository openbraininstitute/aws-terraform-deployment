data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "terraform_remote_state_bucket_name" {
  type        = string
  description = "Bucket name storing the deployment-common tfstate"
  sensitive   = false
}

variable "terraform_remote_state_dynamodb_table" {
  type        = string
  description = "dynamodb table that stores the remote lock"
  sensitive   = false
}

variable "epfl_cidr" {
  type        = string
  default     = "128.178.0.0/15"
  description = "CIDR of the network range used by EPFL"
  sensitive   = false
}

variable "bbp_dmz_cidr" {
  type        = string
  default     = "192.33.211.0/26"
  description = "CIDR of the BBP DMZ, containing bbpproxy, bbpssh bastion host and the proxy for SauceLabs"
  sensitive   = false
}

variable "bb5_login_nodes_cidr" {
  type        = string
  default     = "192.33.194.8/29"
  description = "CIDR of the network range used by BB5 Login Nodes (bbpv1, bbpv2)"
  sensitive   = false
}

variable "bbpssh_cidr" {
  type        = string
  default     = "192.33.211.12/32"
  description = "CIDR of the network range used by SSH Bastion host (BBP SSH Jumphost)"
  sensitive   = false
}

### Virtual Lab Manager service ###

variable "virtual_lab_manager_base_path" {
  default     = "/api/virtual-lab-manager"
  type        = string
  description = "The base path for the virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_log_group_name" {
  default     = "virtual_lab_manager"
  type        = string
  description = "The log name within cloudwatch for the virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_docker_image_url" {
  default     = "bluebrain/obp-virtual-lab-api:latest"
  type        = string
  description = "docker image for the virtual lab manager"
  sensitive   = false
}

### Nexus ###

variable "nise_dockerhub_password" {
  type        = string
  description = "Password for the NISE dockerhub access. Set via TF_VAR_nise_dockerhub_password variable."
  sensitive   = true
}
