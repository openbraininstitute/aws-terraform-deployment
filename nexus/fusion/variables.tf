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

variable "nexus_fusion_base_path" {
  type      = string
  sensitive = false
}

variable "nexus_fusion_docker_image_url" {
  default   = "bluebrain/nexus-web:2.0.0"
  sensitive = false
  type      = string
}

variable "nexus_fusion_client_id" {
  type = string
}

variable "nexus_delta_endpoint" {
  type      = string
  sensitive = false
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent"
}

variable "private_aws_lb_target_group_nexus_fusion_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}

variable "fusion_instance_name" {
  type = string
}

