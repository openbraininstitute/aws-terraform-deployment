is_staging                                = false
is_production                             = false
deployment_env                            = "sandbox-nse"
terraform_remote_state_bucket_name        = "obi-tfstate-sandbox-nse"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test-sandbox-nse"
ml_paper_bucket_name                      = "ml-paper-bucket-sandbox-hpc-test"
ml_neuroagent_bucket_name                 = "ml-neuroagent-staging"
nexus_obp_bucket_name                     = "nexus-obp-sandbox-nse-test"
nexus_ship_bucket_name                    = "nexus-ship-sandbox-nse-test"
nexus_openscience_bucket_name             = "nexus-openscience-sandbox-nse-test"
core_web_app_docker_image_url             = "public.ecr.aws/openbraininstitute/core-web-app:staging"
core_web_app_next_docker_image_url        = "public.ecr.aws/openbraininstitute/core-web-app:entitycore-migration-aws"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:20250226.1"
thumbnail_generation_api_docker_image_url = "bluebrain/thumbnail-generation-api:latest"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:latest"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.5.0"
notebook_service_docker_image_url         = "public.ecr.aws/openbraininstitute/notebook-service:staging"

virtual_lab_manager_task_size = {
  cpu    = 512
  memory = 1024
}

keycloak_task_size = {
  cpu    = 1024
  memory = 2048
}

coreservices_public_key                    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy8UW1JdUjIuiiaI+xFId3smXFe6iwxdn6Klqi8y4E+cFHP/uQxW4AuCfJVoOjOQ2CNU0UIGRlCkw3IwUmZvwGjFZS1Vs6jt+KjWiDRdFzQQrz5+vuqPX2576wXlT+EHe0W6r7Qla5i1L6cjz6/E4u5yFZ3MJQSBYjLqXjT7Da4R72gPx9oiIoSH2JBu3vHyfkTEo3l6C+WJlYnUGOLnUxGGGnhJrBKmIRNMmtRNgQlBkPR4mnCAFABJfgpzgNf4bpqLbma5DabQGbvpX6qCLSAV5Zdd4gBQLIAJfS/a5pMWaIy9qDTWB2vy4Z39HI45k6efrLL+xgo+XYSRqn5jDT heeren@Mac"
hpc_resource_provisioner_container_version = "latest-dev"
core_web_app_deployment_env                = "staging"
core_web_app_next_public_matomo_site_id    = "3"

hpc_resource_provisioner_sbo_nexusdata_bucket = "s3://sbonexusdata-sandbox"
hpc_resource_provisioner_containers_bucket    = "s3://sboinfrastructureassets-sandbox/containers"
hpc_resource_provisioner_scratch_bucket       = "s3://sbosandbox-lec3cn"
pcluster_ami_id                               = ""

entitycore_svc_image_url = "public.ecr.aws/openbraininstitute/entitycore:2025.4.2"

obi_one_docker_image_url            = "public.ecr.aws/openbraininstitute/obi-one:2025.4.2"
obi_generative_gui_docker_image_url = "public.ecr.aws/openbraininstitute/obi-generative-gui:2025.4.5"
