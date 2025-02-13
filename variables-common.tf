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

variable "cell_svc_docker_image_url" {
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
variable "core_web_app_deployment_env" {
  default     = "production"
  type        = string
  description = "env core-web-app is deployed <staging|production>"
  sensitive   = false
}

### BlueNaaS service ###

variable "bluenaas_docker_image_url" {
  type        = string
  description = "Docker image URL for the blue-naas service"
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
  type        = string
  description = "docker image for the virtual lab manager"
  sensitive   = false
}

### Accounting service ###

variable "accounting_base_path" {
  default     = "/api/accounting"
  type        = string
  description = "The base path for the accounting service"
  sensitive   = false
}
variable "coreservices_public_key" {
  type        = string
  description = "Public SSH key for the coreservices team"
  sensitive   = true
}

### Nexus ###

variable "nise_dockerhub_password" {
  type        = string
  description = "Password for the NISE dockerhub access. Set via TF_VAR_nise_dockerhub_password variable."
  sensitive   = true
}

### BlueNaaS ###

variable "bluenaas_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS task (number or string format)"
}

### Keycloak ###

variable "keycloak_task_size" {
  type = object({
    cpu    = number
    memory = number
  })

  description = "CPU and memory limit for Keycloak's ECS task (number or string format)"
}

### HPC ###
variable "hpc_resource_provisioner_container_version" {
  type        = string
  description = "Version of hpc-resource-provisioner to deploy"
}
