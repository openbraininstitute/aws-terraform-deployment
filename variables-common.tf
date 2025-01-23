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

variable "cell_svc_bucket_name" {
  type      = string
  sensitive = false
}

variable "ml_paper_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_domain_name" {
  type      = string
  sensitive = false
}

variable "nexus_obp_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_ship_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_openscience_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_az_letter_id" {
  type = string
}

variable "ec_apikey" {
  type      = string
  sensitive = true
}

variable "core_web_app_docker_image_url" {
  type        = string
  description = "docker image for the core-web-app"
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
