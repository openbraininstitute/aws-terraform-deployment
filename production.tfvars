is_staging                                = false
is_production                             = true
deployment_env                            = "production"
terraform_remote_state_bucket_name        = "obi-tfstate-production"
cell_svc_bucket_name                      = "sbo-cell-svc-perf-test"
ml_paper_bucket_name                      = "ml-paper-bucket"
ml_neuroagent_bucket_name                 = "ml-neuroagent-production"
nexus_domain_name                         = "openbluebrain.com"
nexus_obp_bucket_name                     = "nexus-obp-production"
nexus_ship_bucket_name                    = "nexus-ship-production"
nexus_openscience_bucket_name             = "nexus-openscience-production"
nexus_az_letter_id                        = "b"
core_web_app_docker_image_url             = "public.ecr.aws/openbraininstitute/core-web-app:2025.05.12.1"
virtual_lab_manager_docker_image_url      = "public.ecr.aws/openbraininstitute/virtual-lab-api:2025.05.12.1"
thumbnail_generation_api_docker_image_url = "bluebrain/thumbnail-generation-api:latest"
cell_svc_docker_image_url                 = "public.ecr.aws/openbraininstitute/sonata-cell-position:2025.2.1-prod"
accounting_svc_docker_image_url           = "public.ecr.aws/openbraininstitute/accounting-service:2025.3.1"
me_model_analysis_docker_image_url        = "public.ecr.aws/openbraininstitute/me-model-analysis:2025.04.08.1"
is_nexus_openscience_running              = false
is_nexus_obp_running                      = true
jupyterhub_ec2_type                       = "c7i.4xlarge"

# TODO: replace tag below with a version tag when the CI is ready
bluenaas_docker_image_url = "bluebrain/blue-naas-single-cell:latest"
bluenaas_task_size = {
  cpu    = 16384
  memory = 32768
}

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
core_web_app_deployment_env                = "production"
core_web_app_next_public_matomo_site_id    = "1"

hpc_resource_provisioner_sbo_nexusdata_bucket = ""
sbo_infrastructureassets_bucket               = "s3://sboinfrastructureassets"
hpc_resource_provisioner_containers_bucket    = ""
hpc_resource_provisioner_scratch_bucket       = ""

entitycore_svc_s3_bucket_name            = "entitycore-data-production"
entitycore_svc_s3_bucket_allowed_origins = ["www.openbraininstitute.org"]
entitycore_svc_image_url                 = "public.ecr.aws/openbraininstitute/entitycore:2025.4.2"

obi_one_docker_image_url            = "public.ecr.aws/openbraininstitute/obi-one:2025.5.2"
obi_generative_gui_docker_image_url = "public.ecr.aws/openbraininstitute/obi-generative-gui:2025.5.2"
