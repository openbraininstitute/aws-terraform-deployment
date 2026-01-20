is_staging                                = false
is_production                             = false
deployment_env                            = "sandbox-hpc"
terraform_remote_state_bucket_name        = "obi-tfstate-sandbox-hpc"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test-sandbox-hpc"
ml_neuroagent_bucket_name                 = "ml-neuroagent-sandbox-hpc"
nexus_obp_bucket_name                     = "nexus-obp-sandbox-hpc-test"
nexus_ship_bucket_name                    = "nexus-ship-sandbox-hpc-test"
nexus_openscience_bucket_name             = "nexus-openscience-sandbox-hpc-test"
core_web_app_docker_image_url             = "bluebrain/sbo-core-web-app:2025.1.0-prod"
core_web_app_dev_docker_image_url         = "public.ecr.aws/openbraininstitute/core-web-app:dev"
core_web_app_preview_docker_image_url     = "public.ecr.aws/openbraininstitute/core-web-app:preview"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:20250226.1"
thumbnail_generation_api_docker_image_url = "bluebrain/thumbnail-generation-api:latest"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.5.0"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:latest"
jupyterhub_ec2_type                       = "t3.micro"
notebook_service_docker_image_url         = "public.ecr.aws/openbraininstitute/notebook-service:staging"
notebook_service_cors_allowed_origins     = "[\"https://staging.cell-a.openbraininstitute.org\",\"https://staging.cell-b.openbraininstitute.org\",\"https://dev.openbraininstitute.org\",\"https://staging.openbraininstitute.org\",\"https://preview.openbraininstitute.org\"]"
notebook_service_bucket_name              = "obi-notebook-service-statistics-sandbox-hpc"
notebook_service_aws_k8s_thread_enabled   = false
notebook_service_azure_k8s_thread_enabled = false
notebook_service_aws_accounting_enabled   = false
notebook_service_azure_accounting_enabled = false
notebook_service_azure_storage_account    = ""

keycloak_sbo_realm_url = "https://staging.cell-a.openbraininstitute.org/auth/realms/SBO"
keycloak_url_with_auth = "https://staging.cell-a.openbraininstitute.org/auth/"

neuroagent_image_tag = "neuroagent-v0.11.4"

small_scale_simulator_api_docker_image_url    = "public.ecr.aws/openbraininstitute/single-cell-simulator:api-staging"
small_scale_simulator_worker_docker_image_url = "public.ecr.aws/openbraininstitute/single-cell-simulator:worker-staging"
small_scale_simulator_api_task_size = {
  cpu    = 256
  memory = 512
}
small_scale_simulator_daemon_workers = {
  default = {
    task_size = {
      cpu    = 4096
      memory = 8192
    }
    num_workers_per_task = 4
    queues               = ["high", "medium", "low"]
    num_worker_tasks     = 1
    autoscaler = {
      enabled              = true
      max_num_worker_tasks = 10
    }
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE_SPOT", weight = 100 }
    ]
  }
}

small_scale_simulator_batch_workers = {
  circuit_sim = {
    task_size = {
      cpu    = 8192
      memory = 16384
    }
    num_workers_per_task = 4
    queues               = ["low"]
    max_worker_tasks     = 4
    capacity_provider    = "FARGATE_SPOT"
  }
  mesh_skeletonization = {
    task_size = {
      cpu    = 16384
      memory = 32768
    }
    num_workers_per_task = 1
    queues               = ["mesh_skeletonization"]
    max_worker_tasks     = 8
    capacity_provider    = "FARGATE_SPOT"
  }
}

virtual_lab_manager_task_size = {
  cpu    = 512
  memory = 1024
}

keycloak_task_size = {
  cpu    = 1024
  memory = 2048
}
coreservices_public_key                    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy8UW1JdUjIuiiaI+xFId3smXFe6iwxdn6Klqi8y4E+cFHP/uQxW4AuCfJVoOjOQ2CNU0UIGRlCkw3IwUmZvwGjFZS1Vs6jt+KjWiDRdFzQQrz5+vuqPX2576wXlT+EHe0W6r7Qla5i1L6cjz6/E4u5yFZ3MJQSBYjLqXjT7Da4R72gPx9oiIoSH2JBu3vHyfkTEo3l6C+WJlYnUGOLnUxGGGnhJrBKmIRNMmtRNgQlBkPR4mnCAFABJfgpzgNf4bpqLbma5DabQGbvpX6qCLSAV5Zdd4gBQLIAJfS/a5pMWaIy9qDTWB2vy4Z39HI45k6efrLL+xgo+XYSRqn5jDT heeren@Mac"
hpc_resource_provisioner_container_version = "0.5.12.dev12"

hpc_resource_provisioner_data_bucket        = "s3://sbonexusdata-sandbox"
infrastructureassets_bucket                 = "s3://sboinfrastructureassets-sandbox"
hpc_resource_provisioner_containers_bucket  = "s3://sboinfrastructureassets-sandbox/containers"
hpc_resource_provisioner_scratch_bucket     = "s3://sbosandbox-lec3cn"
hpc_resource_provisioner_scratch_bucket_arn = "arn:aws:s3:::sbosandbox-lec3cn"
pcluster_ami_id                             = "ami-027ff2490377d3048"
hpc_av_zone_suffixes                        = ["a"]

entitycore_svc_aws_s3_internal_bucket    = "sbonexusdata-sandbox" # while testing launch system public data
entitycore_svc_aws_s3_internal_region    = "us-east-1"
entitycore_svc_aws_s3_open_bucket        = "openbluebrain" # while testing launch system public data
entitycore_svc_aws_s3_open_region        = "us-west-2"
entitycore_svc_s3_bucket_allowed_origins = ["*"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2025.9.3"

obi_one_v2_docker_image_url  = "public.ecr.aws/openbraininstitute/obi-one:2025.10.9"
obi_one_v2_ec2_instance_type = "t3.small" # vCPUs: 2, Memory: 2 GiB
obi_one_v2_ecs_task_size = {
  cpu    = 2048
  memory = 1536
  tmpfs  = 512
}

# CoreWebApp s3 and CloudFront configuration
core_webapp_s3_bucket_name = "core-webapp-static-assets-sandbox-hpc"
auth_manager_svc_image_url = "985539765147.dkr.ecr.us-east-1.amazonaws.com/auth-manager:2025.10.28.1"
keycloak_client_uuid       = "569228c5-674f-4f54-b9cb-8d179be66bda"
keycloak_client_id         = "core-webapp-dev"

# launch-system configuration
launch_system_api_task_size = {
  cpu    = 512
  memory = 1024
}
launch_system_orchestrator_task_size = {
  cpu    = 512
  memory = 1024
}
launch_system_executor_task_size = {
  cpu    = 512
  memory = 1024
}

launch_system_orchestrator_num_workers = 2

opendata_paths_list = "staging_opendata_paths.txt"

core_web_app_in_azure_cidr_block = "10.102.1.0/27" # staging azure core web app aca range
