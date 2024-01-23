### Required Infrastructure Information

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "dockerhub_access_iam_policy_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}

variable "nat_gateway_id" {
  type = string
}

variable "domain_zone_id" {
  type = string
}

variable "private_alb_listener_9999_arn" {
  type = string
}

variable "private_alb_dns_name" {
  type = string
}

variable "aws_lb_listener_sbo_https_arn" {
  type = string
}

variable "aws_lb_alb_dns_name" {
  type = string
}

variable "aws_iam_service_linked_role_depends_on" {
  type        = string
  description = "Dependency. The role that allows Amazon ES to manage AWS resources for you. This was shared from a role defined in ML."
}

### Nexus Delta ###

variable "nexus_delta_hostname" {
  type      = string
  default   = "sbo-nexus-delta.shapes-registry.org"
  sensitive = false
}

variable "nexus_delta_docker_image_url" {
  type      = string
  default   = "bluebrain/nexus-delta:1.9.0"
  sensitive = false
}

variable "nexus_app_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for delta app"
}

### Nexus Storage Service ###

variable "nexus_storage_docker_image_url" {
  type      = string
  default   = "bluebrain/nexus-storage:1.10.0-M1"
  sensitive = false
}

### Nexus Fusion ###

variable "nexus_fusion_hostname" {
  default   = "sbo-nexus-fusion.shapes-registry.org"
  type      = string
  sensitive = false
}

variable "nexus_fusion_docker_image_url" {
  default   = "bluebrain/nexus-web:1.9.9"
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
  default   = "t3.small.micro"
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

### Switches

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