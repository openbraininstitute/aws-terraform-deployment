is_staging                                = false
is_production                             = false
deployment_env                            = "sandbox-nse"
terraform_remote_state_bucket_name        = "obi-tfstate-sandbox-nse"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test-sandbox-nse"
nexus_obp_bucket_name                     = "nexus-obp-sandbox-nse-test"
nexus_ship_bucket_name                    = "nexus-ship-sandbox-nse-test"
nexus_openscience_bucket_name             = "nexus-openscience-sandbox-nse-test"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:20250226.1"
thumbnail_generation_api_docker_image_url = "bluebrain/thumbnail-generation-api:latest"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:latest"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.5.0"
grading_service_docker_image_url          = "985539765147.dkr.ecr.us-east-1.amazonaws.com/grading-service:latest"
jupyterhub_ec2_type                       = "t3.micro"
notebook_service_docker_image_url         = "992382665735.dkr.ecr.us-east-1.amazonaws.com/notebook-service:staging"
notebook_service_bucket_name              = "obi-notebook-service-statistics-staging"
notebook_service_aws_k8s_thread_enabled   = false
notebook_service_azure_k8s_thread_enabled = false
notebook_service_aws_accounting_enabled   = false
notebook_service_azure_accounting_enabled = false
notebook_service_azure_storage_account    = ""

keycloak_sbo_realm_url = "https://staging.cell-a.openbraininstitute.org/auth/realms/SBO"
keycloak_url_with_auth = "https://staging.cell-a.openbraininstitute.org/auth/"

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

virtual_lab_manager_task_size = {
  cpu    = 512
  memory = 1024
}

multiple_vlabs_allowed_user_id = "16588c8b-ec88-4a49-a413-a0bb3a7b8541"

keycloak_db_instance_class = "db.t4g.micro"

keycloak_task_size = {
  cpu    = 1024
  memory = 2048
}

coreservices_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy8UW1JdUjIuiiaI+xFId3smXFe6iwxdn6Klqi8y4E+cFHP/uQxW4AuCfJVoOjOQ2CNU0UIGRlCkw3IwUmZvwGjFZS1Vs6jt+KjWiDRdFzQQrz5+vuqPX2576wXlT+EHe0W6r7Qla5i1L6cjz6/E4u5yFZ3MJQSBYjLqXjT7Da4R72gPx9oiIoSH2JBu3vHyfkTEo3l6C+WJlYnUGOLnUxGGGnhJrBKmIRNMmtRNgQlBkPR4mnCAFABJfgpzgNf4bpqLbma5DabQGbvpX6qCLSAV5Zdd4gBQLIAJfS/a5pMWaIy9qDTWB2vy4Z39HI45k6efrLL+xgo+XYSRqn5jDT heeren@Mac"

hpc_resource_provisioner_data_bucket        = "s3://sbonexusdata-sandbox"
infrastructureassets_bucket                 = "s3://sboinfrastructureassets-sandbox"
hpc_resource_provisioner_containers_bucket  = "s3://sboinfrastructureassets-sandbox/containers"
hpc_resource_provisioner_scratch_bucket     = "s3://sbosandbox-b4kr2"
hpc_resource_provisioner_scratch_bucket_arn = "arn:aws:s3:::sbosandbox-b4kr2"
pcluster_ami_id                             = ""
hpc_av_zone_suffixes                        = ["a"]

entitycore_svc_aws_s3_internal_bucket    = "entitycore-data-sandbox-nse"
entitycore_svc_aws_s3_internal_region    = "us-east-1"
entitycore_svc_aws_s3_open_bucket        = "openbluebrain"
entitycore_svc_aws_s3_open_region        = "us-west-2"
entitycore_svc_s3_bucket_allowed_origins = ["*"]

entitycore_svc_image_url = "public.ecr.aws/openbraininstitute/entitycore:2025.4.2"

obi_one_v2_docker_image_url  = "public.ecr.aws/openbraininstitute/obi-one:2025.10.4"
obi_one_v2_ec2_instance_type = "t3.small" # vCPUs: 2, Memory: 2 GiB
obi_one_v2_ecs_task_size = {
  cpu    = 2048
  memory = 1536
  tmpfs  = 512
}

# CoreWebApp s3 and CloudFront configuration
auth_manager_svc_image_url          = "985539765147.dkr.ecr.us-east-1.amazonaws.com/auth-manager:2026.04.08.1"
keycloak_client_uuid                = "a40fd6ea-79f8-4212-b087-45c75e4703a4"
keycloak_client_id                  = "core-webapp-cell-b-azure-staging"
core_web_app_stripe_publishable_key = "placeholder"

core_web_app_in_azure_cidr_block = "10.102.1.0/27" # staging azure core web app aca range

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

launch_system_aca_in_azure_cidr_block   = "10.120.0.0/16"
launch_system_batch_in_azure_cidr_block = "10.122.0.0/16"

# the bucket must exist in the sandbox and it must be versioned
launch_system_private_data_s3_bucket_name = "test-s3-files-gf-009203151042-us-east-1-an"

azure_blobstore_opendata_container_url             = "https://obibatchstoragestg.blob.core.windows.net/opendata"
azure_blobstore_internal_public_data_container_url = "https://obibatchstoragestg.blob.core.windows.net/publicdata"
azure_blobstore_opendata_sas_token                 = "placeholder"
azure_blobstore_internal_public_data_sas_token     = "placeholder"
azure_datasync_agent_activation_key_uswest2        = "placeholder"
azure_datasync_agent_activation_key_useast1        = "placeholder"
azure_nfs_server_hostname                          = "obibatchnfsstg.file.core.windows.net"
azure_nfs_opendata_path                            = "/obibatchnfsstg/opendata"
azure_nfs_internal_public_data_path                = "/obibatchnfsstg/publicdata"
resource_provisioner_container_hash                = "1837363b2413d5e7cfd8c7a859ba4b3cd35c685acd4240f70101364aaaeee0b8"
resource_provisioner_container_uri                 = "985539765147.dkr.ecr.us-east-1.amazonaws.com/hpc-resource-provisioner:0.5.13.dev8"

pcs_ami                 = "ami-0fa11a6354572d8b5"
pcs_large_instance_type = "c5n.large" # 2 vCPUs, 5.3 GiB
pcs_large_enable_efa    = false
