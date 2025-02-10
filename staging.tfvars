is_production                         = false
terraform_remote_state_dynamodb_table = "terraform-state-lock-table-staging"
terraform_remote_state_bucket_name    = "obi-tfstate-staging"
cell_svc_bucket_name                  = "sbo-cell-svc-perf-test-staging"
ml_paper_bucket_name                  = "ml-paper-bucket-staging-test"
nexus_domain_name                     = "staging.openbluebrain.com"
nexus_obp_bucket_name                 = "nexus-obp-production-staging-test"
nexus_ship_bucket_name                = "nexus-ship-production-staging-test"
nexus_openscience_bucket_name         = "nexus-openscience-production-staging-test"
nexus_az_letter_id                    = "a"
core_web_app_docker_image_url         = "bluebrain/sbo-core-web-app:staging"
virtual_lab_manager_docker_image_url  = "bluebrain/obp-virtual-lab-api:staging"
is_nexus_openscience_running          = false
is_nexus_obp_running                  = true

bluenaas_docker_image_url = "bluebrain/blue-naas-single-cell:staging"
bluenaas_task_size = {
  cpu    = 4096
  memory = 8192
}

keycloak_task_size = {
  cpu    = 1024
  memory = 2048
}
