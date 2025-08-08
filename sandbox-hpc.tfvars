is_staging                                = false
is_production                             = false
deployment_env                            = "sandbox-hpc"
terraform_remote_state_bucket_name        = "obi-tfstate-sandbox-hpc"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test-sandbox-hpc"
ml_paper_bucket_name                      = "ml-paper-bucket-sandbox-hpc-test"
ml_neuroagent_bucket_name                 = "ml-neuroagent-staging"
nexus_obp_bucket_name                     = "nexus-obp-sandbox-hpc-test"
nexus_ship_bucket_name                    = "nexus-ship-sandbox-hpc-test"
nexus_openscience_bucket_name             = "nexus-openscience-sandbox-hpc-test"
core_web_app_docker_image_url             = "bluebrain/sbo-core-web-app:2025.1.0-prod"
core_web_app_next_docker_image_url        = "public.ecr.aws/openbraininstitute/core-web-app:entitycore-migration-aws"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:20250226.1"
thumbnail_generation_api_docker_image_url = "bluebrain/thumbnail-generation-api:latest"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.5.0"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:latest"
is_nexus_openscience_running              = false
is_nexus_obp_running                      = true
jupyterhub_ec2_type                       = "c7i.4xlarge"
notebook_service_docker_image_url         = "public.ecr.aws/openbraininstitute/notebook-service:staging"

bluenaas_docker_image_url = "public.ecr.aws/openbraininstitute/single-cell-simulator:staging"
bluenaas_task_size = {
  cpu    = 4096
  memory = 8192
}

small_scale_simulator_api_docker_image_url    = "public.ecr.aws/openbraininstitute/single-cell-simulator:api-staging"
small_scale_simulator_worker_docker_image_url = "public.ecr.aws/openbraininstitute/single-cell-simulator:worker-staging"
small_scale_simulator_api_task_size = {
  cpu    = 256
  memory = 512
}
small_scale_simulator_workers = {
  default = {
    task_size = {
      cpu    = 4096
      memory = 8192
    }
    num_workers             = 4
    queues                  = "high medium low"
    autoscaler_min_capacity = 1
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE_SPOT", weight = 100 }
    ]
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
core_web_app_deployment_env                = "staging"
core_web_app_next_public_matomo_site_id    = "3"

hpc_resource_provisioner_sbo_nexusdata_bucket = "s3://sbonexusdata-sandbox"
sbo_infrastructureassets_bucket               = "s3://sboinfrastructureassets-sandbox"
hpc_resource_provisioner_containers_bucket    = "s3://sboinfrastructureassets-sandbox/containers"
hpc_resource_provisioner_scratch_bucket       = "s3://sbosandbox-lec3cn"
hpc_resource_provisioner_scratch_bucket_arn   = "arn:aws:s3:::sbosandbox-lec3cn"
pcluster_ami_id                               = "ami-027ff2490377d3048"

entitycore_svc_aws_s3_internal_bucket    = "entitycore-data-staging"
entitycore_svc_aws_s3_internal_region    = "us-east-1"
entitycore_svc_aws_s3_open_bucket        = "openbluebrain"
entitycore_svc_aws_s3_open_region        = "us-west-2"
entitycore_svc_s3_bucket_allowed_origins = ["*"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2025.4.2"

obi_one_docker_image_url = "public.ecr.aws/openbraininstitute/obi-one:2025.4.2"
obi_one_task_size = {
  cpu    = 512
  memory = 1024
}
obi_generative_gui_docker_image_url = "public.ecr.aws/openbraininstitute/obi-generative-gui:2025.4.5"
