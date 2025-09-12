is_staging                                = true
is_production                             = false
deployment_env                            = "staging"
terraform_remote_state_bucket_name        = "obi-tfstate-staging"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test-staging"
ml_paper_bucket_name                      = "ml-paper-bucket-staging-test"
ml_neuroagent_bucket_name                 = "ml-neuroagent-staging"
nexus_obp_bucket_name                     = "nexus-obp-production-staging-test"
nexus_ship_bucket_name                    = "nexus-ship-production-staging-test"
nexus_openscience_bucket_name             = "nexus-openscience-production-staging-test"
core_web_app_docker_image_url             = "public.ecr.aws/openbraininstitute/core-web-app:staging"
core_web_app_dev_docker_image_url         = "public.ecr.aws/openbraininstitute/core-web-app:dev"
core_web_app_preview_docker_image_url     = "public.ecr.aws/openbraininstitute/core-web-app:preview"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:staging"
thumbnail_generation_api_docker_image_url = "public.ecr.aws/openbraininstitute/thumbnail-generation-api:staging"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.9.0"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:latest"
jupyterhub_ec2_type                       = "c7i.large"
notebook_service_docker_image_url         = "public.ecr.aws/openbraininstitute/notebook-service:staging"
notebook_hub_on_eks_full_url              = "https://jupyterhub.staging.openbrainplatform.com/hub/"
notebook_service_cors_allowed_origins     = "https://dev.openbraininstitute.org,https://staging.openbraininstitute.org,https://preview.openbraininstitute.org"

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

coreservices_public_key                    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO8QAh2WZ/WcZnNeojPNhadeodMO2l3PssaUFJWfvEFNzkuo5ci7nxb39M2FH6RyFAfqykV/v89KfDIg9K2ebJQZS+x6Enrqm7+ROmZjCdpYkFm7l2NCoKLus92DaPX6k1Tv5hcI76BqWN4nOKQxzb7ziJxFl5wzLgTwnXZvY33dA3Pu6aimksv071KnQ3hJKk6Omx/l7Hv/D7c0tU8vRCUefzHT3TkRpRgTTq+Wd8S0pGSmMB4drk5PiUzEVczxuIfmYGCWV2va6aT34yuMOw/6y2Cr9guCkyR2FkFm7q0MPw0aKGFBwTT05eiEWBWKQQbqi1qMtSwd6tp4qv6crN SSH key for AWS SBO POC"
hpc_resource_provisioner_container_version = "latest"

hpc_resource_provisioner_data_bucket        = "s3://obi-hpc-data-staging"
infrastructureassets_bucket                 = "s3://sboinfrastructureassets-staging"
hpc_resource_provisioner_containers_bucket  = "s3://sboinfrastructureassets-staging/containers"
hpc_resource_provisioner_scratch_bucket     = "s3://obi-hpc-scratch-staging"
hpc_resource_provisioner_scratch_bucket_arn = "arn:aws:s3:::obi-hpc-scratch-staging"
pcluster_ami_id                             = ""
hpc_av_zone_suffixes                        = ["a"]

entitycore_svc_aws_s3_internal_bucket    = "entitycore-data-staging"
entitycore_svc_aws_s3_internal_region    = "us-east-1"
entitycore_svc_aws_s3_open_bucket        = "openbluebrain"
entitycore_svc_aws_s3_open_region        = "us-west-2"
entitycore_svc_s3_bucket_allowed_origins = ["*"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2025.9.2"

obi_one_docker_image_url = "public.ecr.aws/openbraininstitute/obi-one:2025.9.0"
obi_one_task_size = {
  cpu    = 512
  memory = 1024
}
obi_generative_gui_docker_image_url = "public.ecr.aws/openbraininstitute/obi-generative-gui:2025.5.4"

# CoreWebApp s3 and CloudFront configuration
core_webapp_s3_bucket_name = "core-webapp-static-assets-staging"
