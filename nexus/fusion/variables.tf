# Shared in nexus module

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

variable "aws_service_discovery_http_namespace_arn" {
  type = string
}

# Fusion specific

variable "nexus_fusion_hostname" {
  type      = string
  sensitive = false
}

variable "nexus_fusion_docker_image_url" {
  default   = "bluebrain/nexus-web:1.10.0-M2-fix-tag-data-download"
  sensitive = false
  type      = string
}

variable "nexus_delta_hostname" {
  type      = string
  sensitive = false
}

variable "nexus_fusion_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for nexus fusion"
}

# Temporary

variable "aws_lb_target_group_nexus_fusion_arn" {
  type = string
}

variable "dockerhub_access_iam_policy_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}
