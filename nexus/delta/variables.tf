variable "aws_region" {
  type = string
}

variable "nexus_delta_hostname" {
  type    = string
  default = "sbo-nexus-delta.shapes-registry.org"
}

variable "nexus_delta_docker_image_url" {
  type    = string
  default = "bluebrain/nexus-delta:1.10.0-M6"
}

variable "subnet_id" {
  type = string
}

variable "postgres_host" {
  type = string
}

variable "elasticsearch_endpoint" {
  type = string
}

variable "blazegraph_endpoint" {
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

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent"
}

variable "nexus_secrets_arn" {
  type        = string
  description = "The ARN of the secrets manager secret that contains the nexus secrets"
}

# temporary
variable "aws_lb_target_group_nexus_app_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}
