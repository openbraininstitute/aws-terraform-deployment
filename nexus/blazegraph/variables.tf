variable "subnet_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_security_group_id" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

variable "aws_service_discovery_http_namespace_arn" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent"
}

# Blazegraph specific

variable "blazegraph_cpu" {
  type        = number
  description = "vCPU value for blazegraph task"
}

variable "blazegraph_memory" {
  type        = number
  description = "RAM value for blazegraph task"
}

variable "blazegraph_instance_name" {
  type        = string
  description = "The name of this Blazegraph instance"
}

variable "blazegraph_efs_name" {
  type        = string
  description = "The name of the EFS for Blazegraph"
}

variable "blazegraph_port" {
  type        = number
  default     = 9999
  description = "The port on which this Blazegraph instance is available"
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
