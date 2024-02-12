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

variable "core_webapp_hostname" {
  default     = "sbo-core-webapp.shapes-registry.org"
  type        = string
  description = "The hostname for the core webapp"
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

### SBO cell service ###

variable "cell_svc_hostname" {
  default     = "sbo-cell-svc.shapes-registry.org"
  type        = string
  description = "The hostname for the cell svc"
  sensitive   = false
}

variable "cell_svc_log_group_name" {
  default     = "cell_svc"
  type        = string
  description = "The log name within cloudwatch for the cell svc"
  sensitive   = false
}

variable "cell_svc_docker_image_url" {
  default     = "bluebrain/obp-sonata-cell-position:latest"
  type        = string
  description = "docker image for the sonata-cell-service"
  sensitive   = false
}

### Machine Learning Embedder ###
variable "embedder_docker_image_url" {
  type        = string
  default     = "bluebrain/bbs-embeddings:bbsembeddings_multi-qa-mpnet-base-dot-v1-1.0.2"
  description = "docker image for the embedder webapp"
  sensitive   = false
}

variable "embedder_log_group_name" {
  default     = "embedder"
  type        = string
  description = "The log name within cloudwatch for the embedder webapp"
  sensitive   = false
}

### Machine Learning ElasticSearch/OpenSearch ###
# Note: you can also request opensearch, but then you need
# to also change the instance type to a type which is compatible
# with opensearch.
variable "ml_opensearch_version" {
  type      = string
  default   = "OpenSearch_2.5"
  sensitive = false
}

variable "ml_opensearch_instance_type" {
  type      = string
  default   = "t3.medium.search"
  sensitive = false
}

variable "ml_os_domain_name" {
  type      = string
  default   = "mlos"
  sensitive = false
}

### VIZ Brayns renderer service ###

variable "viz_brayns_log_group_name" {
  default     = "viz_brayns"
  type        = string
  description = "The log name within cloudwatch for Brayns"
  sensitive   = false
}

variable "viz_brayns_hostname" {
  default     = "private-alb-sbo-brayns.shapes-registry.org"
  type        = string
  description = "Hostname at which Brayns containers can be reached via the private ALB"
  sensitive   = false
}

variable "viz_brayns_docker_image_url" {
  type        = string
  default     = "bluebrain/spackah-brayns:3.4.1"
  description = "Docker image for Brayns renderer service"
  sensitive   = false
}

variable "viz_bcsb_docker_image_url" {
  type        = string
  default     = "bluebrain/spackah-bcsb:2.1.2"
  description = "Docker image for BCSB service"
  sensitive   = false
}

## VIZ PostgreSQL ###

variable "viz_postgresql_database_port" {
  default   = 5432
  type      = number
  sensitive = false
}

variable "viz_postgresql_database_name" {
  type      = string
  default   = "vsm"
  sensitive = false
}

variable "viz_postgresql_database_username" {
  type      = string
  default   = "vsm"
  sensitive = false
}

variable "viz_postgresql_admin_username" {
  type      = string
  default   = "admin"
  sensitive = false
}

# VIZ VSM

variable "viz_vsm_log_group_name" {
  default     = "viz_vsm"
  type        = string
  description = "The log name within cloudwatch for VSM"
  sensitive   = false
}

variable "viz_vsm_proxy_log_group_name" {
  default     = "viz_vsm_proxy"
  type        = string
  description = "The log name within cloudwatch for VSM-Proxy"
  sensitive   = false
}

variable "viz_vsm_hostname" {
  default     = "sbo-vsm.shapes-registry.org"
  type        = string
  description = "Hostname at which VSM container can be reached via the ALB"
  sensitive   = false
}

variable "viz_vsm_proxy_hostname" {
  default     = "sbo-vsm-proxy.shapes-registry.org"
  type        = string
  description = "Hostname at which VSM-Proxy container can be reached via the ALB"
  sensitive   = false
}

variable "viz_vsm_docker_image_url" {
  type        = string
  default     = "bluebrain/vsm:latest"
  description = "Docker image for VSM services"
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