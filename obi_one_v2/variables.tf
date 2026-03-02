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

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "ecs_task_size" {
  type = object({
    cpu    = any
    memory = any
    tmpfs  = any # tmpfs size in MiB
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

variable "mount_base_dir" {
  description = "Base directory for all the mountpoints in ECS, used to prefix for both volume_host_path and volume_container_path."
  type        = string
  validation {
    condition     = can(regex("^(/.*)?$", var.mount_base_dir))
    error_message = "mount_base_dir must be empty or start with /"
  }
}

variable "mount_buckets" {
  description = "List of buckets to be mounted in EC2 and accessible in ECS."
  type = list(object({
    bucket_name           = string # Name of the bucket containing data to be mounted
    bucket_region         = string # Region of the bucket containing data to be mounted
    bucket_prefix         = string # Prefix for data to be mounted, must end with / if not empty
    volume_name           = string # Name of the volume to be mounted
    volume_host_path      = string # Path of the mounted volume on the host, should be set to /{storage_type}/{bucket_prefix}
    volume_container_path = string # Path of the mounted volume in the container, should be set to /{storage_type}/{bucket_prefix}
    mount_extra_options   = string # Additional options to pass to mount-s3
  }))
  validation {
    condition = alltrue([
      for m in var.mount_buckets : (
        can(regex("^(.*/)?$", m.bucket_prefix)) &&
        can(regex("^/", m.volume_host_path)) &&
        can(regex("^/", m.volume_container_path))
      )
    ])
    error_message = "Each bucket_prefix must end with '/', and host/container paths must start with '/'."
  }
  validation {
    condition = alltrue([
      length(var.mount_buckets) == length(distinct([for m in var.mount_buckets : m.volume_name])),
      length(var.mount_buckets) == length(distinct([for m in var.mount_buckets : m.volume_host_path])),
      length(var.mount_buckets) == length(distinct([for m in var.mount_buckets : m.volume_container_path]))
    ])
    error_message = "Each of volume_name, volume_host_path, and volume_container_path must be unique."
  }
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "entitycore_url" {
  description = "entitycore URL"
  type        = string
}

variable "launch_system_url" {
  description = "launch system URL"
  type        = string
}

variable "accounting_base_url" {
  description = "accounting base URL"
  type        = string
}

variable "virtual_lab_api_url" {
  description = "virtual lab manager URL"
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

variable "cors_origins" {
  description = "CORS origins"
  type        = list(string)
}

variable "cors_origin_regex" {
  description = "CORS origin regex"
  type        = string
  default     = null
}
