variable "subnet_id" {
  type        = string
  description = "ID of the subnet in which NGINX should run"
}

variable "subnet_security_group_id" {
  type        = string
  description = "Security group applied to the resource which should describe how the resource can communicate inside the subnet."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS Cluster in which NGINX should run."
}

variable "nginx_efs_name" {
  type        = string
  description = "Unique name for the EFS associated with Nginx. This is where the Nginx config are stored and later mounted to the container."
}

variable "dockerhub_credentials_arn" {
  type        = string
  description = "ARN of the secret that contains valid Dockerhub credentials to pull docker images while authenticated."
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent."
}

variable "desired_count" {
  type        = number
  description = "Number of tasks that the service should run. Set to 0 to not run anything."
  default     = 1
}

variable "delta_nginx_target_group_arn" {
  type        = string
  description = "ARN of the target group that the ECS Service will be targeted by."
}

variable "aws_service_discovery_http_namespace_arn" {
  type        = string
  description = "The ARN of the ECS Service Discover namespace in which the NGINX task will be included."
}

variable "domain_name" {
  type = string
}
