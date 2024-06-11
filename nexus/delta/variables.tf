variable "aws_region" {
  type = string
}

variable "delta_instance_name" {
  type        = string
  description = "name to use to parametrize the different components in this module"
}

variable "delta_efs_name" {
  type        = string
  description = "name for the efs associated with delta"
}

variable "nexus_delta_hostname" {
  type    = string
  default = "sbo-nexus-delta.shapes-registry.org"
}

variable "nexus_delta_docker_image_url" {
  type    = string
  default = "bluebrain/nexus-delta:latest"
}

variable "s3_bucket_arn" {
  type        = string
  description = "arn of the bucket that delta will use for s3 storage"
}

variable "subnet_id" {
  type        = string
  description = "id of the subnet in which delta should run"
}

variable "postgres_host" {
  type        = string
  description = "address of the postgres instance delta should use"
}

variable "postgres_host_read_replica" {
  type = string
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "endpoint of the elasticsearch instance delta should use"
}

variable "blazegraph_endpoint" {
  type        = string
  description = "endpoint of the blazegraph instance delta should use"
}

variable "subnet_security_group_id" {
  type        = string
  description = "security group applied to the resource which should describe how the resource can communicate inside the subnet"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "arn of the ecs cluster in which delta should run"
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
