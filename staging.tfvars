is_staging                                = true
is_production                             = false
deployment_env                            = "staging"
terraform_remote_state_bucket_name        = "obi-tfstate-staging"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test-staging"
ml_paper_bucket_name                      = "ml-paper-bucket-staging-test"
ml_neuroagent_bucket_name                 = "ml-neuroagent-staging"
nexus_domain_name                         = "staging.openbluebrain.com"
nexus_obp_bucket_name                     = "nexus-obp-production-staging-test"
nexus_ship_bucket_name                    = "nexus-ship-production-staging-test"
nexus_openscience_bucket_name             = "nexus-openscience-production-staging-test"
nexus_az_letter_id                        = "a"
core_web_app_docker_image_url             = "public.ecr.aws/openbraininstitute/core-web-app:staging"
core_web_app_next_docker_image_url        = "public.ecr.aws/openbraininstitute/core-web-app:entitycore-migration-aws"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:staging"
thumbnail_generation_api_docker_image_url = "public.ecr.aws/openbraininstitute/thumbnail-generation-api:staging"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.5.0"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:latest"
me_model_analysis_docker_image_url        = "public.ecr.aws/openbraininstitute/me-model-analysis:staging"
is_nexus_openscience_running              = false
is_nexus_obp_running                      = true
jupyterhub_ec2_type                       = "c7i.large"
notebook_service_docker_image_url         = "public.ecr.aws/openbraininstitute/notebook-service:staging"


bluenaas_docker_image_url = "public.ecr.aws/openbraininstitute/single-cell-simulator:staging"
bluenaas_task_size = {
  cpu    = 4096
  memory = 8192
}

virtual_lab_manager_task_size = {
  cpu    = 512
  memory = 1024
}

keycloak_task_size = {
  cpu    = 2048
  memory = 4096
}
coreservices_public_key                    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDO8QAh2WZ/WcZnNeojPNhadeodMO2l3PssaUFJWfvEFNzkuo5ci7nxb39M2FH6RyFAfqykV/v89KfDIg9K2ebJQZS+x6Enrqm7+ROmZjCdpYkFm7l2NCoKLus92DaPX6k1Tv5hcI76BqWN4nOKQxzb7ziJxFl5wzLgTwnXZvY33dA3Pu6aimksv071KnQ3hJKk6Omx/l7Hv/D7c0tU8vRCUefzHT3TkRpRgTTq+Wd8S0pGSmMB4drk5PiUzEVczxuIfmYGCWV2va6aT34yuMOw/6y2Cr9guCkyR2FkFm7q0MPw0aKGFBwTT05eiEWBWKQQbqi1qMtSwd6tp4qv6crN SSH key for AWS SBO POC"
hpc_resource_provisioner_container_version = "latest"
core_web_app_deployment_env                = "staging"
core_web_app_next_public_matomo_site_id    = "3"

hpc_resource_provisioner_sbo_nexusdata_bucket = ""
sbo_infrastructureassets_bucket               = "s3://sboinfrastructureassets-staging"
hpc_resource_provisioner_containers_bucket    = ""
hpc_resource_provisioner_scratch_bucket       = ""

entitycore_svc_s3_bucket_name            = "entitycore-data-staging"
entitycore_svc_s3_bucket_allowed_origins = ["*"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2025.6.4"

obi_one_docker_image_url            = "public.ecr.aws/openbraininstitute/obi-one:2025.6.1"
obi_generative_gui_docker_image_url = "public.ecr.aws/openbraininstitute/obi-generative-gui:2025.5.4"
