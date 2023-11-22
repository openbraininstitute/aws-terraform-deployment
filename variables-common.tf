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
  default     = "192.33.194.10/31"
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

### Nexus Delta ###

variable "nexus_delta_hostname" {
  type      = string
  default   = "sbo-nexus-delta.shapes-registry.org"
  sensitive = false
}

variable "nexus_delta_docker_image_url" {
  type      = string
  default   = "bluebrain/nexus-delta:1.8.0"
  sensitive = false
}

variable "nexus_delta_app_log_group_name" {
  default   = "nexus_delta_app"
  type      = string
  sensitive = false
}

### Nexus Fusion ###

variable "nexus_fusion_hostname" {
  default   = "sbo-nexus-fusion.shapes-registry.org"
  type      = string
  sensitive = false
}

variable "nexus_fusion_docker_image_url" {
  default   = "bluebrain/nexus-web:1.8.5"
  sensitive = false
  type      = string
}

variable "nexus_fusion_log_group_name" {
  default   = "nexus_fusion_app"
  type      = string
  sensitive = false
}

### Nexus Blazegraph ###

variable "blazegraph_docker_image_url" {
  default   = "bluebrain/blazegraph-nexus:2.1.6-RC"
  sensitive = false
  type      = string
}

# Directory for /var/lib/blazegraph/data on the EFS filesystem
variable "efs_blazegraph_data_dir" {
  default   = "/blazegraph-data-dir"
  sensitive = false
  type      = string
}

# Directory for /var/lib/blazegraph/log4j on the EFS filesystem, should contain the
# log4j.properties file
variable "efs_blazegraph_log4j_dir" {
  default   = "/blazegraph-log4j-dir"
  sensitive = false
  type      = string
}

variable "blazegraph_app_log_group_name" {
  default   = "blazegraph_app"
  sensitive = false
  type      = string
}

variable "private_blazegraph_hostname" {
  default     = "private-alb-blazegraph.shapes-registry.org"
  type        = string
  description = "Hostname at which the blazegraph containers can be reached via the private ALB"
  sensitive   = false
}

### Nexus ElasticSearch/OpenSearch ###

# Note: you can also request opensearch, but then you need
# to also change the instance type to a type which is compatible
# with opensearch.
variable "nexus_elasticsearch_version" {
  type      = string
  default   = "Elasticsearch_7.10"
  sensitive = false
}

variable "nexus_elasticsearch_instance_type" {
  type      = string
  default   = "t3.small.search"
  sensitive = false
}

variable "nexus_es_domain_name" {
  type      = string
  default   = "nexus"
  sensitive = false
}

### Nexus PostgreSQL ###

variable "nexus_postgresql_database_port" {
  default   = 5432
  type      = number
  sensitive = false
}

variable "nexus_postgresql_database_name" {
  type      = string
  default   = "nexus_user"
  sensitive = false
}

variable "nexus_postgresql_database_username" {
  type      = string
  default   = "nexus_user"
  sensitive = false
}
#variable "nexus_postgresql_database_password" {
#  type = string
#  sensitive = true
#}

variable "nexus_postgresql_admin_username" {
  type      = string
  default   = "admin"
  sensitive = false
}

#variable "nexus_postgresql_admin_password" {
#  type      = string
#  sensitive = true
#}

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

variable "private_ml_embedder_hostname" {
  default     = "private-alb-embedder.shapes-registry.org"
  type        = string
  description = "Hostname at which the embedder containers can be reached via the private ALB"
  sensitive   = false
}

### Machine Learning Reader ###
variable "ml_reader_docker_image_url" {
  type        = string
  default     = "bluebrain/bbs-question-answering:biom-electra-large-squad2-v1.2.1"
  description = "docker image for the ML Reader webapp"
  sensitive   = false
}

variable "ml_reader_log_group_name" {
  default     = "ml_reader"
  type        = string
  description = "The log name within cloudwatch for the ML Reader webapp"
  sensitive   = false
}

variable "private_ml_reader_hostname" {
  default     = "private-alb-ml-reader.shapes-registry.org"
  type        = string
  description = "Hostname at which the ML Reader containers can be reached via the private ALB"
  sensitive   = false
}

### Machine Learning Backend ###
variable "ml_backend_docker_image_url" {
  type        = string
  default     = "bluebrain/bbs-pipeline:v0.5.1"
  description = "docker image for the ML backend"
  sensitive   = false
}

variable "ml_backend_log_group_name" {
  default     = "ml_backend"
  type        = string
  description = "The log name within cloudwatch for the ML backend"
  sensitive   = false
}

variable "private_ml_backend_hostname" {
  default     = "private-alb-ml-backend.shapes-registry.org"
  type        = string
  description = "Hostname at which the ML backend containers can be reached via the private ALB"
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
  default   = "t3.small.search"
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
  default     = "bluebrain/spackah-brayns:3.3.0"
  description = "Docker image for Brayns renderer service"
  sensitive   = false
}

variable "viz_bcsb_docker_image_url" {
  type        = string
  default     = "bluebrain/spackah-bcsb:2.1.0"
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
