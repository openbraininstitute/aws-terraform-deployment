variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "allowed_source_ip_cidr_blocks" {
  description = "List of CIDR blocks to allow access to the service"
  type        = list(string)
}

variable "internet_access_route_id" {
  type = string
}

variable "private_alb_listener_arn" {
  type = string
}

variable "deployment_env" {
  type        = string
  description = "The deployment environment, values: 'staging', 'production'"
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
}

variable "cors_origins" {
  description = "CORS origins"
  type        = list(string)
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "api_image_url" {
  description = "Image for the API"
  type        = string
}

variable "orchestrator_image_url" {
  description = "Image for the orchestrator"
  type        = string
}

variable "default_executor_image_url" {
  description = "Image for the default executor"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
}

variable "db_instance_class" {
  description = "The instance class to use for the RDS instance."
  type        = string
}

variable "db_allocated_storage" {
  description = "The amount of storage to allocate for the RDS instance (in gigabytes)."
  type        = number
}


variable "secrets_arn" {
  # Need the following secrets:
  # DB_PASS
  # AZURE_CLIENT_SECRET
  # AZURE_CLIENT_ID
  # AZURE_TENANT_ID
  # AZ_SUBSCRIPTION_ID
  # AZ_BATCH_ACCOUNT_NAME
  # AZ_BATCH_POOL_NAME
  # AZ_UPLOAD_BLOB_SAS_URL
  # GITHUB_DEPLOY_KEY_B64__inait

  type = string
}

variable "obi_backup_plan" {
  description = "Name of the OBI backup plan"
  type        = string
}


variable "cluster_task_maximum_runtime" {
  type = string
}

variable "simulation_launch_command" {
  description = "Base command used to launch the simulations."
  type        = string
}

variable "entitycore_url" {
  description = "URL of entitycore"
  type        = string
}

variable "auth_manager_url" {
  description = "URL of the auth-manager service"
  type        = string
}

variable "launch_system_api_url" {
  description = "URL of the launch system API"
  type        = string
}

variable "ec_node_type" {
  description = "Type of node for ElastiCache."
}

variable "tags" {
  description = "Tags of the resources."
  type        = map(string)
  default     = { SBO_Billing = "launch_system" }
}

variable "api_task_size" {
  type = object({
    cpu    = any
    memory = any
  })
  description = "CPU and memory limit for the API task (number or string format)"
}

variable "orchestrator_task_size" {
  type = object({
    cpu    = any
    memory = any
  })
  description = "CPU and memory limit for the orchestrator task (number or string format)"
}

variable "executor_task_size" {
  type = object({
    cpu    = any
    memory = any
  })
  description = "CPU and memory limit for the executor tasks (number or string format)"
}

variable "orchestrator_num_workers" {
  description = "Number of workers processing the queues in the orchestrator task."
  type        = number
}

variable "queues" {
  description = "List of Redis queues."
  type        = list(string)
}


variable "public_launch_data_efs_id" {
  description = "The ID for the EFS on which the public data lives"
  type        = string
}

variable "internal_public_data_access_point_id" {
  description = "The ID for the access point with internal public data"
  type        = string
}

variable "open_public_data_access_point_id" {
  description = "The ID for the access point with open public data"
  type        = string
}

variable "local_store_prefix" {
  description = "Base location where public data is mounted."
  type        = string
}

variable "codeartifact_config" {
  description = "Configuration for AWS CodeArtifact Python repository access"
  type = object({
    domain       = string
    domain_owner = string
    repository   = string
    region       = string
  })

  validation {
    condition = (
      length(var.codeartifact_config.domain) > 0 &&
      length(var.codeartifact_config.domain_owner) > 0 &&
      length(var.codeartifact_config.repository) > 0 &&
      length(var.codeartifact_config.region) > 0
    )
    error_message = "All CodeArtifact configuration fields must be non-empty strings."
  }
}
