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
  default     = "bluebrain/sbo-core-web-app:439c86c0-1680702285"
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
  default   = "bluebrain/nexus-delta:1.8.0-M10"
  sensitive = false
}

variable "nexus_delta_app_log_group_name" {
  default   = "nexus_delta_app"
  type      = string
  sensitive = false
}

variable "nexus_web_app_log_group_name" {
  default   = "nexus_web_app"
  type      = string
  sensitive = false
}

### Nexus Fusion ###

variable "nexus_fusion_hostname" {
  default   = "sbo-nexus-fusion.shapes-registry.org"
  type      = string
  sensitive = false
}

variable "nexus_web_docker_image_url" {
  default   = "bluebrain/nexus-delta:1.8.0-M15"
  sensitive = false
  type      = string
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
  default   = "nexus_db"
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

### HPC compute instances ###
variable "num_compute_instances" {
  default   = 2
  type      = number
  sensitive = false
}
