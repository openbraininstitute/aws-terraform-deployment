data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "terraform_remote_state_bucket_name" {
  type        = string
  description = "Bucket name storing the deployment-common tfstate"
  sensitive   = false
}

variable "cell_svc_bucket_name" {
  type      = string
  sensitive = false
}

variable "cell_svc_docker_image_url" {
  type      = string
  sensitive = false
}

variable "ml_neuroagent_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_obp_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_ship_bucket_name" {
  type      = string
  sensitive = false
}

variable "nexus_openscience_bucket_name" {
  type      = string
  sensitive = false
}

### Core Web App ###

variable "core_web_app_docker_image_url" {
  type        = string
  description = "docker image for the core-web-app"
  sensitive   = false
}

variable "core_web_app_dev_docker_image_url" {
  default     = null
  type        = string
  description = "docker image for the core-web-app-dev"
  sensitive   = false
}

variable "core_web_app_preview_docker_image_url" {
  default     = null
  type        = string
  description = "docker image for the core-web-app-preview"
  sensitive   = false
}

variable "core_web_app_stripe_publishable_key" {
  type        = string
  description = "Stripe publishable key for the core-web-app"
}

variable "neuroagent_docker_image_url" {
  default     = null
  type        = string
  description = "docker image for neuroagent"
  sensitive   = false
}

variable "core_webapp_s3_bucket_name" {
  type        = string
  description = "S3 bucket name for core webapp main assets"
  sensitive   = false
}

### Small Scale Simulator ###

variable "small_scale_simulator_api_docker_image_url" {
  type        = string
  description = "Docker image URL for the small scale simulator API"
}

variable "small_scale_simulator_worker_docker_image_url" {
  type        = string
  description = "Docker image URL for the small scale simulator worker"
}

variable "small_scale_simulator_api_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for the API ECS task (number or string format)"
}

variable "small_scale_simulator_daemon_workers" {
  type = map(object({
    task_size = object({
      cpu    = any
      memory = any
    })
    num_workers_per_task = number
    queues               = list(string)
    num_worker_tasks     = optional(number, 1)
    autoscaler = optional(object({
      enabled              = optional(bool, false)
      max_num_worker_tasks = optional(number, 10)
    }), {})
    capacity_provider_strategy = list(object({
      capacity_provider = string # Valid values: FARGATE, FARGATE_SPOT
      weight            = number
    }))
  }))

  description = "Map of daemon worker configurations for small scale simulator. Each key represents a worker service name with optional auto-scaling configuration."
}

variable "small_scale_simulator_batch_workers" {
  type = map(object({
    task_size = object({
      cpu    = any
      memory = any
    })
    num_workers_per_task = number
    queues               = list(string)
    max_worker_tasks     = number
    capacity_provider    = string # Valid values: FARGATE, FARGATE_SPOT
  }))

  description = "Map of batch worker configurations. Each key represents an on-demand worker auto-provisioned based on CloudWatch job queue length metrics."
  default     = {}
}

### Virtual Lab Manager service ###

variable "virtual_lab_manager_base_path" {
  default     = "/api/virtual-lab-manager"
  type        = string
  description = "The base path for the virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_log_group_name" {
  default     = "virtual_lab_manager"
  type        = string
  description = "The log name within cloudwatch for the virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_docker_image_url" {
  type        = string
  description = "Docker image for the virtual lab manager"
  sensitive   = false
}

variable "virtual_lab_manager_task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS task (number or string format) for virtual lab manager"
}

### Accounting service ###

variable "accounting_svc_docker_image_url" {
  type        = string
  description = "Docker image for the accounting service"
}

variable "accounting_svc_base_path" {
  default     = "/api/accounting"
  type        = string
  description = "The base path for the accounting service"
}

variable "coreservices_public_key" {
  type        = string
  description = "Public SSH key for the coreservices team"
  sensitive   = true
}

### Notebook service ###

variable "notebook_service_docker_image_url" {
  type        = string
  description = "Docker image for the notebook service"
}

variable "notebook_service_accounting_enabled" {
  type        = bool
  description = "Should accounting be enabled in the notebook service?"
}

### Keycloak ###

variable "keycloak_task_size" {
  type = object({
    cpu    = number
    memory = number
  })

  description = "CPU and memory limit for Keycloak's ECS task (number or string format)"
}

variable "jupyterhub_ec2_type" {
  type        = string
  description = "JupyterHub service Amazon EC2 Instance type"
  default     = "t3.small"
}

### HPC ###
variable "hpc_resource_provisioner_container_version" {
  type        = string
  description = "Version of hpc-resource-provisioner to deploy"
}

variable "hpc_resource_provisioner_data_bucket" {
  type        = string
  description = "S3 bucket in which OBI data lives. Includes s3:// prefix and sub-path, if any"
}

variable "hpc_resource_provisioner_containers_bucket" {
  type        = string
  description = "S3 bucket in which containers can be found. Includes s3:// prefix and sub-path, if any"
}

variable "hpc_resource_provisioner_scratch_bucket" {
  type        = string
  description = "S3 bucket in which scratch space lives. Includes s3:// prefix and sub-path, if any"
}

variable "hpc_resource_provisioner_scratch_bucket_arn" {
  type        = string
  description = "ARN for the hpc_resource_provisioner_scratch_bucket"
}

variable "infrastructureassets_bucket" {
  type        = string
  description = "S3 bucket in which infrastructure assets are stored"
}

variable "pcluster_ami_id" {
  type = string
}

variable "hpc_av_zone_suffixes" {
  type = list(string)
}

### entitycore ###
variable "entitycore_svc_aws_s3_internal_bucket" {
  type        = string
  description = "S3 bucket name in which entitycore data lives."
}

variable "entitycore_svc_aws_s3_internal_region" {
  type        = string
  description = "S3 region name in which entitycore data lives."
}

variable "entitycore_svc_aws_s3_open_bucket" {
  type        = string
  description = "S3 bucket name in which open data lives."
}

variable "entitycore_svc_aws_s3_open_region" {
  type        = string
  description = "S3 region name in which open data lives."
}

variable "entitycore_svc_s3_bucket_allowed_origins" {
  type        = list(string)
  description = "Allowed origins for the entitycore service"
}

variable "entitycore_svc_image_url" {
  type        = string
  description = "Image URL for entitycore service."
}


variable "thumbnail_generation_api_docker_image_url" {
  type        = string
  description = "Docker image for the thumbnail generation api"
  sensitive   = false
}

variable "obi_one_v2_docker_image_url" {
  type        = string
  description = "Docker image URL for obi-one service."
}

variable "obi_one_v2_ec2_instance_type" {
  type        = string
  description = "EC2 instance type to run obi-one ECS tasks."
}

variable "obi_one_v2_ecs_task_size" {
  type = object({
    cpu    = any
    memory = any
    tmpfs  = any # tmpfs size in MiB
  })
  description = "CPU and memory limit for obi-one ECS task (number or string format)"
}

variable "notebook_hub_on_eks_full_url" {
  type        = string
  description = "URL of /hub of the JupyterHub on EKS instance, needed for the notebooks service"
}

variable "notebook_service_cors_allowed_origins" {
  type        = string
  description = "JSON encoded list of allowed origins for the cors settings of the notebook service"
}

variable "notebook_service_k8s_thread_enabled" {
  type        = string
  description = "Enable kubernetes background thread to check how long notebooks run"
}

variable "notebook_service_bucket_name" {
  type = string
}

variable "auth_manager_svc_image_url" {
  type        = string
  description = "Image URL for auth manager service."
}


variable "keycloak_client_uuid" {
  type        = string
  description = "UUID of the Keycloak client"
}

variable "keycloak_client_id" {
  type        = string
  description = "ID of the Keycloak client"
}


### launch-system ###

variable "launch_system_api_task_size" {
  type = object({
    cpu    = any
    memory = any
  })
  description = "CPU and memory limit for launch-system API task (number or string format)"
}

variable "launch_system_orchestrator_task_size" {
  type = object({
    cpu    = any
    memory = any
  })
  description = "CPU and memory limit for launch-system orchestrator task (number or string format)"
}

variable "launch_system_executor_task_size" {
  type = object({
    cpu    = any
    memory = any
  })
  description = "CPU and memory limit for launch-system executor tasks (number or string format)"
}

variable "launch_system_orchestrator_num_workers" {
  description = "Number of workers processing the queues in the orchestrator task."
  type        = number
}

variable "opendata_paths_list" {
  type        = string
  description = "File in which the paths to sync on opendata are listed, one per line. Should exist in modules/public_data_efs"
}
