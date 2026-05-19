is_staging                                = false
is_production                             = true
deployment_env                            = "production"
terraform_remote_state_bucket_name        = "obi-tfstate-production"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test"
ml_neuroagent_bucket_name                 = "ml-neuroagent-production"
nexus_obp_bucket_name                     = "nexus-obp-production"
nexus_ship_bucket_name                    = "nexus-ship-production"
nexus_openscience_bucket_name             = "nexus-openscience-production"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:2026.05.06.1"
thumbnail_generation_api_docker_image_url = "public.ecr.aws/openbraininstitute/thumbnail-generation-api:2026.03.27.1"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2026.2.0"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:2026.04.2"
jupyterhub_ec2_type                       = "c7i.2xlarge"
notebook_service_docker_image_url         = "985539765147.dkr.ecr.us-east-1.amazonaws.com/notebook-service:2026.05.19-1"
notebook_service_bucket_name              = "obi-notebook-service-statistics-prod"
notebook_service_aws_k8s_thread_enabled   = true
notebook_service_azure_k8s_thread_enabled = true
notebook_service_aws_accounting_enabled   = true
notebook_service_azure_accounting_enabled = true
notebook_service_azure_storage_account    = "obijupstorageprod"

keycloak_sbo_realm_url = "https://cell-a.openbraininstitute.org/auth/realms/SBO"
keycloak_url_with_auth = "https://cell-a.openbraininstitute.org/auth/"

neuroagent_docker_image_url = "985539765147.dkr.ecr.us-east-1.amazonaws.com/neuroagent:neuroagent-v0.17.3"

neuroagent_typescript_docker_image_url = "985539765147.dkr.ecr.us-east-1.amazonaws.com/neuroagent:neuroagent-ts-v0.1.5"

ml_neuroagent_typescript_bucket_name = "ml-neuroagent-typescript-production"
ml_typescript_subnet_a_cidr          = "10.0.9.0/24"
ml_typescript_subnet_b_cidr          = "10.0.7.0/24"
grading_service_docker_image_url     = "985539765147.dkr.ecr.us-east-1.amazonaws.com/grading-service:2026.05.01.1"

small_scale_simulator_api_docker_image_url    = "public.ecr.aws/openbraininstitute/single-cell-simulator:api-2026.05.04.1"
small_scale_simulator_worker_docker_image_url = "public.ecr.aws/openbraininstitute/single-cell-simulator:worker-2026.05.04.1"
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
    num_workers_per_task = 4
    queues               = ["high", "medium"]
    num_worker_tasks     = 1
    autoscaler = {
      enabled              = true
      max_num_worker_tasks = 10
    }
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE", weight = 100 }
    ]
  }
  large = {
    task_size = {
      cpu    = 16384
      memory = 32768
    }
    num_workers_per_task = 12
    queues               = ["medium", "low"]
    num_worker_tasks     = 1
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE", weight = 100 },
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
    capacity_provider    = "FARGATE"
  }
}

core_web_app_stripe_publishable_key = "pk_live_51QjjHBKGUR5u3ofL3U1YQwXofi5vIEpo6mOfWOVqBiV6aWy0Gz7y6h1lMos5uzTseL2UExqBMuYq5uwUUWZss5SH00dP35riR3"

virtual_lab_manager_task_size = {
  cpu    = 1024
  memory = 2048
}

multiple_vlabs_allowed_user_id = "a713cff1-d67d-4f3f-9c28-a92fae3ddf30"

keycloak_task_size = {
  cpu    = 2048
  memory = 4096
}
coreservices_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO8QAh2WZ/WcZnNeojPNhadeodMO2l3PssaUFJWfvEFNzkuo5ci7nxb39M2FH6RyFAfqykV/v89KfDIg9K2ebJQZS+x6Enrqm7+ROmZjCdpYkFm7l2NCoKLus92DaPX6k1Tv5hcI76BqWN4nOKQxzb7ziJxFl5wzLgTwnXZvY33dA3Pu6aimksv071KnQ3hJKk6Omx/l7Hv/D7c0tU8vRCUefzHT3TkRpRgTTq+Wd8S0pGSmMB4drk5PiUzEVczxuIfmYGCWV2va6aT34yuMOw/6y2Cr9guCkyR2FkFm7q0MPw0aKGFBwTT05eiEWBWKQQbqi1qMtSwd6tp4qv6crN SSH key for AWS SBO POC"

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
entitycore_svc_s3_bucket_allowed_origins = ["*"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2026.5.1"

obi_one_v2_docker_image_url  = "985539765147.dkr.ecr.us-east-1.amazonaws.com/obi-one:2026.5.3"
obi_one_v2_ec2_instance_type = "t3.large" # vCPUs: 2, Memory: 8 GiB
obi_one_v2_ecs_task_size = {
  cpu    = 2048
  memory = 7680
  tmpfs  = 512
}

# CoreWebApp s3 and CloudFront configuration
auth_manager_svc_image_url = "985539765147.dkr.ecr.us-east-1.amazonaws.com/auth-manager:2026.04.08.1"
keycloak_client_uuid       = "5c060da0-5f9f-4a35-b9fd-32c5fafb1aca"
keycloak_client_id         = "core-webapp-cell-b-azure"

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

opendata_paths_list = "production_opendata_paths.txt"

core_web_app_in_azure_cidr_block = "10.103.1.0/27" # staging azure core web app aca range

# From https://github.com/openbraininstitute/azure-terraform-deployment/blob/562f3fc/production.tfvars#L25
launch_system_aca_in_azure_cidr_block = "10.121.0.0/16"
# From https://github.com/openbraininstitute/azure-terraform-deployment/blob/0d9b29e/production.tfvars#L30
launch_system_batch_in_azure_cidr_block = "10.123.0.0/16"

azure_blobstore_opendata_container_url             = "https://obibatchstorageprod.blob.core.windows.net/opendata"
azure_blobstore_internal_public_data_container_url = "https://obibatchstorageprod.blob.core.windows.net/publicdata"

azure_nfs_server_hostname           = "obibatchnfsprod.file.core.windows.net"
azure_nfs_opendata_path             = "/obibatchnfsprod/opendata"
azure_nfs_internal_public_data_path = "/obibatchnfsprod/publicdata"

resource_provisioner_container_hash = "1837363b2413d5e7cfd8c7a859ba4b3cd35c685acd4240f70101364aaaeee0b8"
resource_provisioner_container_uri  = "985539765147.dkr.ecr.us-east-1.amazonaws.com/hpc-resource-provisioner:0.5.13.dev8"

pcs_ami = "ami-0cfcd37a2d4cec1dc"

datasync_target_account                = "992382665735"
destination_entitycore_internal_bucket = "entitycore-data-staging"
