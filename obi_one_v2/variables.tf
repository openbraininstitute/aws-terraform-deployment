variable "log_group_name" {
  default     = "obi_one_v2"
  type        = string
  description = "The log name within cloudwatch for the service"
  sensitive   = false
}

variable "docker_image_url" {
  type        = string
  description = "Docker image for the service"
  sensitive   = false
}

variable "obi_one_v2_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the service"
}

variable "shared_bucket_name" {
  type = string
  description = "Name of the bucket containing data to be mounted"
}

variable "shared_bucket_prefix" {
  type = string
  description = "Prefix for public data to be mounted"
}

variable "ec2_instance_type" {
  type = string
  description = "EC2 instance type"
}

variable "ecs_task_size" {
  type = object({
    cpu    = any
    memory = any
    tmpfs  = any  # tmpfs size in MiB
  })
  description = "CPU and memory limit for ECS task (number or string format)"
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

variable "private_alb_https_listener_arn" {
  type = string
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
}

variable "host_port" {
  description = "Internal host port"
  type        = number
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "mounted_volume_name" {
  description = "Name of the volume to be mounted"
  type        = string
}

variable "mounted_volume_host_path" {
  description = "Path of the mounted volume on the host"
  type        = string
}

variable "mounted_volume_container_path" {
  description = "Path of the mounted volume in the container"
  type        = string
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "aws_coreservices_ssh_key_id" {
  type = string
}

variable "amazon_linux_ecs_ami_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "tags" {
  description = "Tags"
  default     = { SBO_Billing = "obi_one_v2" }
  type        = map(string)
}
