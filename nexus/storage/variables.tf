variable "aws_region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "subnet_security_group_id" {
  type        = string
  description = "security group applied to the resource which should describe how the resource can communicate inside the subnet"
}

variable "ecs_cluster_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "amazon_linux_ecs_ami_id" {
  type = string
}

variable "aws_service_discovery_http_namespace_arn" {
  type = string
}

# Specific storage service config

variable "s3_bucket_name" {
  type    = string
  default = "sbonexusdata"
}

variable "nexus_storage_ecs_number_of_containers" {
  type    = number
  default = 1
}

variable "nexus_storage_docker_image_url" {
  type      = string
  default   = "bluebrain/nexus-storage:latest"
  sensitive = false
}
