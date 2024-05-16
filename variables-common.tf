data "aws_caller_identity" "current" {}

variable "aws_region" {
  type      = string
  default   = "us-east-1"
  sensitive = false
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

variable "sbo_https_test_hostname" {
  default     = "sbo-https-test.shapes-registry.org"
  type        = string
  description = "The default endpoint for the application load balancer"
  sensitive   = false
}

### SBO core webapp ###

# TODO: delete after migration to the production domain.
variable "core_webapp_poc_hostname" {
  default     = "sbo-core-webapp.shapes-registry.org"
  type        = string
  description = "The hostname for the core webapp poc"
  sensitive   = false
}

variable "core_webapp_hostname" {
  default     = "openbrainplatform.org"
  type        = string
  description = "The hostname for the core webapp"
  sensitive   = false
}

# TODO: update to "/app/core" after migration to the production domain.
variable "core_webapp_base_path" {
  default     = "/mmb-beta"
  type        = string
  description = "The base path for the core webapp"
  sensitive   = false
}

variable "core_webapp_log_group_name" {
  default     = "core_webapp"
  type        = string
  description = "The log name within cloudwatch for the core webapp"
  sensitive   = false
}

variable "core_webapp_docker_image_url" {
  default     = "bluebrain/sbo-core-web-app:latest"
  type        = string
  description = "docker image for the core webapp"
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

### BBP Workflow ###

variable "workflow_log_group_name" {
  default     = "bbp-workflow"
  type        = string
  description = "The log name within cloudwatch for bbp-workflow"
  sensitive   = false
}

variable "workflow_docker_image_url" {
  description = "docker url for bbp-workflow on dockerhub"
  type        = string
  default     = "bluebrain/bbp-workflow:latest"
  sensitive   = false
}

variable "bbp_workflow_hostname" {
  default     = "bbp-workflow.shapes-registry.org"
  type        = string
  description = "Hostname bbp-workflow"
  sensitive   = false
}

variable "bbp_workflow_api_hostname" {
  default     = "bbp-workflow-api.shapes-registry.org"
  type        = string
  description = "Hostname bbp-workflow-api"
  sensitive   = false
}

variable "bbp_workflow_web_hostname" {
  default     = "bbp-workflow-web.shapes-registry.org"
  type        = string
  description = "Hostname bbp-workflow-web"
  sensitive   = false
}


### Thumbnail Generation API ###

variable "thumbnail_generation_api_docker_image_url" {
  default     = "bluebrain/thumbnail-generation-api:latest"
  type        = string
  description = "docker image for the thumbnail generation api"
  sensitive   = false
}

variable "thumbnail_generation_api_hostname" {
  default     = "thumbnail-generation-api.shapes-registry.org"
  type        = string
  description = "The hostname for the thumbnail generation api"
  sensitive   = false
}

variable "thumbnail_generation_api_log_group_name" {
  default     = "thumbnail_generation_api"
  type        = string
  description = "The log name within cloudwatch for the thumbnail generation api"
  sensitive   = false
}

### KG Inference API ###

variable "kg_inference_api_docker_image_url" {
  default     = "bluebrain/kg-inference-api:latest"
  type        = string
  description = "docker image for the KG Inference API"
  sensitive   = false
}

variable "kg_inference_api_hostname" {
  default     = "kg-inference-api.shapes-registry.org"
  type        = string
  description = "The hostname for the KG Inference API"
  sensitive   = false
}

variable "keycloak_server_url" {
  default     = "https://sboauth.epfl.ch/auth/"
  type        = string
  description = "The URL of the Keycloak server"
  sensitive   = false
}

variable "kg_inference_api_log_group_name" {
  default     = "kg_inference_api"
  type        = string
  description = "The log name within cloudwatch for the kg inference api"
  sensitive   = false
}