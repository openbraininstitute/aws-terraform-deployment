
variable "subnet_id" {
  type        = string
  description = "The ID of the subnet in which Blazegraph will be deployed."
}

variable "subnet_security_group_id" {
  type = string
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ARN of the ECS Cluster where the Blazegraph service & taks will be deployed."
}

variable "aws_service_discovery_http_namespace_arn" {
  type        = string
  description = "The ARN of the ECS Service Discover namespace in which the Blazegraph task will be included. This is so that Delta (that will be in the same namespace) can call Blazegraph without the use of a load balancer."
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent"
}

variable "dockerhub_credentials_arn" {
  type        = string
  description = "ARN of the secret that contains valid Dockerhub credentials to pull docker images while authenticated."
}

# Blazegraph specific

variable "blazegraph_cpu" {
  type        = number
  description = "vCPU value for the blazegraph task"
}

variable "blazegraph_memory" {
  type        = number
  description = "RAM value for the blazegraph task"
}

variable "blazegraph_java_opts" {
  type        = string
  description = "JAVA_OPTS for Blazegraph"
}

variable "blazegraph_instance_name" {
  type        = string
  description = "The unique name of this Blazegraph instance"
}

variable "blazegraph_efs_name" {
  type        = string
  description = "The unique name of the EFS for Blazegraph"
}

variable "blazegraph_port" {
  type        = number
  default     = 9999
  description = "The port on which this Blazegraph instance is available"
}

variable "blazegraph_docker_image_url" {
  type    = string
  default = "bluebrain/blazegraph-nexus:2.1.6-RC"
}

variable "efs_blazegraph_data_dir" {
  type        = string
  default     = "/blazegraph-data-dir"
  description = "The EFS directory that will be mounted to /var/lib/blazegraph/data on the Blazegraph container. This is where the Blazegraph journal is located."
}
