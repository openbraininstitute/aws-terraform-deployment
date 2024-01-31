variable "subnet_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "subnet_security_group_id" {
  type = string
}

variable "domain_zone_id" {
  type = string
}

variable "private_alb_listener_9999_arn" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

# Blazegraph specific

variable "private_blazegraph_hostname" {
  type        = string
  description = "Hostname at which the blazegraph containers can be reached via the private ALB"
  sensitive   = false
}

variable "blazegraph_ecs_number_of_containers" {
  type      = number
  default   = 1
  sensitive = false
}

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
