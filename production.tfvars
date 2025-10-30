is_staging                                = false
is_production                             = true
deployment_env                            = "production"
terraform_remote_state_bucket_name        = "obi-tfstate-production"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test"
ml_paper_bucket_name                      = "ml-paper-bucket"
ml_neuroagent_bucket_name                 = "ml-neuroagent-production"
nexus_obp_bucket_name                     = "nexus-obp-production"
nexus_ship_bucket_name                    = "nexus-ship-production"
nexus_openscience_bucket_name             = "nexus-openscience-production"
core_web_app_docker_image_url             = "public.ecr.aws/openbraininstitute/core-web-app:2025.10.28.1"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:2025.10.28.1"
thumbnail_generation_api_docker_image_url = "public.ecr.aws/openbraininstitute/thumbnail-generation-api:2025.10.27.1"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.9.0"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:2025.10.1"
jupyterhub_ec2_type                       = "c7i.2xlarge"
notebook_service_docker_image_url         = "public.ecr.aws/openbraininstitute/notebook-service:2025.10.28-1"
notebook_hub_on_eks_full_url              = "none"
notebook_service_cors_allowed_origins     = "[\"https://www.openbraininstitute.org\"]"
notebook_service_bucket_name              = "obi-notebook-service-statistics-prod"
notebook_service_k8s_thread_enabled       = false
notebook_service_accounting_enabled       = false

small_scale_simulator_api_docker_image_url    = "public.ecr.aws/openbraininstitute/single-cell-simulator:api-2025.10.28.1"
small_scale_simulator_worker_docker_image_url = "public.ecr.aws/openbraininstitute/single-cell-simulator:worker-2025.10.28.1"
small_scale_simulator_api_task_size = {
  cpu    = 1024
  memory = 2048
}
small_scale_simulator_daemon_workers = {
  small = {
    task_size = {
      cpu    = 4096
      memory = 8192
    }
    num_workers_per_task = 2
    queues               = ["high", "medium"]
    num_worker_tasks     = 1
    autoscaler = {
      enabled              = true
      max_num_worker_tasks = 10
    }
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE_SPOT", weight = 100 }
    ]
  }
  large = {
    task_size = {
      cpu    = 16384
      memory = 32768
    }
    num_workers_per_task = 12
    queues               = ["high", "medium", "low"]
    num_worker_tasks     = 1
    autoscaler = {
      enabled              = true
      max_num_worker_tasks = 10
    }
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE", weight = 100 },
    ]
  }
}
small_scale_simulator_batch_workers = {}

virtual_lab_manager_task_size = {
  cpu    = 1024
  memory = 2048
}

keycloak_task_size = {
  cpu    = 2048
  memory = 4096
}
coreservices_public_key                    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO8QAh2WZ/WcZnNeojPNhadeodMO2l3PssaUFJWfvEFNzkuo5ci7nxb39M2FH6RyFAfqykV/v89KfDIg9K2ebJQZS+x6Enrqm7+ROmZjCdpYkFm7l2NCoKLus92DaPX6k1Tv5hcI76BqWN4nOKQxzb7ziJxFl5wzLgTwnXZvY33dA3Pu6aimksv071KnQ3hJKk6Omx/l7Hv/D7c0tU8vRCUefzHT3TkRpRgTTq+Wd8S0pGSmMB4drk5PiUzEVczxuIfmYGCWV2va6aT34yuMOw/6y2Cr9guCkyR2FkFm7q0MPw0aKGFBwTT05eiEWBWKQQbqi1qMtSwd6tp4qv6crN SSH key for AWS SBO POC"
hpc_resource_provisioner_container_version = "latest"

hpc_resource_provisioner_data_bucket        = "s3://obi-hpc-data"
infrastructureassets_bucket                 = "s3://sboinfrastructureassets"
hpc_resource_provisioner_containers_bucket  = "s3://sboinfrastructureassets/containers"
hpc_resource_provisioner_scratch_bucket     = "s3://obi-hpc-scratch"
hpc_resource_provisioner_scratch_bucket_arn = "arn:aws:s3:::obi-hpc-scratch"
pcluster_ami_id                             = ""
hpc_av_zone_suffixes                        = ["a"]

entitycore_svc_aws_s3_internal_bucket    = "entitycore-data-production"
entitycore_svc_aws_s3_internal_region    = "us-east-1"
entitycore_svc_aws_s3_open_bucket        = "openbluebrain"
entitycore_svc_aws_s3_open_region        = "us-west-2"
entitycore_svc_s3_bucket_allowed_origins = ["https://www.openbraininstitute.org"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2025.10.8"

obi_one_v2_docker_image_url  = "public.ecr.aws/openbraininstitute/obi-one:2025.10.6"
obi_one_v2_ec2_instance_type = "t3.large" # vCPUs: 2, Memory: 8 GiB
obi_one_v2_ecs_task_size = {
  cpu    = 2048
  memory = 7680
  tmpfs  = 512
}

# CoreWebApp s3 and CloudFront configuration
core_webapp_s3_bucket_name = "core-webapp-static-assets-production"
