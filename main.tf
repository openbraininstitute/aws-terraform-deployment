locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id

  private_alb_https_listener_arn = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
  route_table_public_id          = data.terraform_remote_state.common.outputs.route_table_public_id

  core_web_app_origins = concat(
    ["https://${local.primary_domain}"],
    var.is_staging ? [
      "http://127.0.0.1:3000",
      "http://localhost:3000",
      "https://preview.openbraininstitute.org",
      "https://dev.openbraininstitute.org",
    ] : []
  )

  vpc_cidr_block    = data.terraform_remote_state.common.outputs.vpc_cidr_block
  vpc_default_sg_id = data.terraform_remote_state.common.outputs.vpc_default_sg_id

  primary_domain    = data.terraform_remote_state.common.outputs.primary_domain
  email_domain_name = data.terraform_remote_state.common.outputs.email_domain_name

  virtual_lab_manager_secrets_arn      = data.terraform_remote_state.common.outputs.virtual_lab_manager_secrets_arn
  keycloak_secrets_arn                 = data.terraform_remote_state.common.outputs.keycloak_secrets_arn
  jupyterhub_secrets_arn               = data.terraform_remote_state.common.outputs.jupyterhub_secrets_arn
  core_webapp_secrets_arn              = data.terraform_remote_state.common.outputs.core_webapp_secrets_arn
  ml_secrets_arn                       = data.terraform_remote_state.common.outputs.ml_secrets_arn
  small_scale_simulator_secrets_arn    = data.terraform_remote_state.common.outputs.small_scale_simulator_secrets_arn
  accounting_service_secrets_arn       = data.terraform_remote_state.common.outputs.accounting_service_secrets_arn
  entitycore_service_secrets_arn       = data.terraform_remote_state.common.outputs.entitycore_service_secrets_arn
  hpc_slurm_secrets_arn                = data.terraform_remote_state.common.outputs.hpc_slurm_secrets_arn
  notebook_service_secrets_arn         = data.terraform_remote_state.common.outputs.notebook_service_secrets_arn
  launch_system_secrets_arn            = data.terraform_remote_state.common.outputs.launch_system_secrets_arn
  virtual_lab_manager_db_ro_secret_arn = data.terraform_remote_state.common.outputs.virtual_lab_manager_database_readonly_secret_arn
  accounting_db_ro_secret_arn          = data.terraform_remote_state.common.outputs.accounting_database_readonly_secret_arn
  teams_webhook_secrets_arn            = data.terraform_remote_state.common.outputs.teams_webhook_secrets_arn
  auth_manager_secrets_arn             = data.terraform_remote_state.common.outputs.auth_manager_secrets_arn

  cloudfront_certificate_arn = data.terraform_remote_state.common.outputs.cloudfront_certificate_arn

  github_organisation = "openbraininstitute"
}

module "coreservices_key" {
  source = "./ssh_key"

  # Stored at:
  # systems/services/external/aws/ssh/aws_coreservices_public_key
  # systems/services/external/aws/ssh/aws_coreservices_private_key
  # systems/services/external/aws/ssh/aws_coreservices_password
  name       = "aws_coreservices"
  public_key = var.coreservices_public_key
}

module "networking" {
  source = "./networking"

  vpc_id         = local.vpc_id
  aws_region     = local.aws_region
  vpc_cidr_block = local.vpc_cidr_block
  route_table_id = local.route_table_private_subnets_id
}

module "github_oidc_provider" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
}


module "cs" {
  source = "./cs"

  is_production                  = var.is_production
  is_staging                     = var.is_staging
  vpc_id                         = local.vpc_id
  route_table_private_subnets_id = local.route_table_private_subnets_id
  route_table_public_subnets_id  = local.route_table_public_id
  db_instance_class              = "db.t3.micro"
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  keycloak_secrets_arn           = local.keycloak_secrets_arn
  keycloak_task_size             = var.keycloak_task_size
  aws_coreservices_ssh_key_id    = module.coreservices_key.key_pair_id
  vpc_cidr_block                 = local.vpc_cidr_block
  aws_region                     = local.aws_region
  nat_gateway_id                 = data.terraform_remote_state.common.outputs.nat_gateway_id
  aws_endpoints_subnet_cidr      = module.networking.endpoints_subnet_cidr

  domain_name = local.primary_domain

  jupyterhub_secrets_arn = local.jupyterhub_secrets_arn
  jupyterhub_ec2_type    = var.jupyterhub_ec2_type

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
}

module "backups" {
  source = "./backups"
}

module "aws_backups_sns_to_teams" {
  source = "./sns_lambda_to_teams"

  unique_name          = "aws_backups" # to make sure certain roles and secrets have a unique name
  sns_topic_arn        = module.backups.sns_topic_arn
  python_script_name   = "aws_backups_sns_to_teams.py"
  python_function_name = "handle_backup_event"
  handler              = "aws_backups_sns_to_teams.handle_backup_event"
  python_runtime       = "python3.11"

  secret_recovery_window_in_days = 7
}

module "aws_errors_sns_topic" {
  source = "./aws_errors_sns_topic"
}

module "debug_aws_errors_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.aws_errors_sns_topic.sns_topic_arn
  unique_short_name         = "aws_errors"
  message_retention_seconds = 172800 # 2 days
}

module "generic_aws_errors_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = "generic_aws_errors"

  unique_short_name = "generic_aws_errors"
  sns_topic_arn     = module.aws_errors_sns_topic.sns_topic_arn
  python_runtime    = "python3.13"
  handler           = "aws_json_log_sns_to_teams.handle_eventbridge_aws_error_event"
}

# to be replaced soon
# module "deployments_sns_to_teams" {
#   source = "./sns_lambda_to_teams"

#   unique_name          = "aws_deployments" # to make sure certain roles and secrets have a unique name
#   sns_topic_arn        = module.deployments_sns_topic.sns_topic_arn
#   python_script_name   = "aws_deployments_sns_to_teams.py"
#   python_function_name = "handle_deployment_event"
#   handler              = "aws_deployments_sns_to_teams.handle_deployment_event"
#   python_runtime       = "python3.11"

#   secret_recovery_window_in_days = 7
# }

module "notebookservice_cloudwatch_error_log_entries_to_sns" {
  source = "./cloudwatch_error_log_entries_to_sns"

  log_group_name    = module.notebook_service.log_group_name
  unique_short_name = "notebook_service"
  region            = local.aws_region
}

module "debug_notebookservice_cloudwatch_error_log_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.notebookservice_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  unique_short_name         = "notebook_service"
  message_retention_seconds = 172800 # 2 days
}

module "notebookservice_error_log_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = "notebook_service_logs_errors"

  unique_short_name = "notebook_service"
  sns_topic_arn     = module.notebookservice_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  python_runtime    = "python3.13"
}

module "entitycore_cloudwatch_error_log_entries_to_sns" {
  source = "./cloudwatch_error_log_entries_to_sns"

  log_group_name    = module.entitycore_svc.log_group_name
  unique_short_name = "entity_core"
  region            = local.aws_region
  filter_pattern    = "{ $.level = \"ERROR\" || $.level = \"WARNING\" }"
}

module "debug_entitycore_cloudwatch_error_log_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.entitycore_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  unique_short_name         = "entitycore"
  message_retention_seconds = 172800 # 2 days
}

module "entitycore_error_log_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = "entity_core_logs_errors"

  unique_short_name = "entity_core"
  sns_topic_arn     = module.entitycore_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  python_runtime    = "python3.13"
}

module "accounting_cloudwatch_error_log_entries_to_sns" {
  source = "./cloudwatch_error_log_entries_to_sns"

  log_group_name    = module.accounting_svc.log_group_name
  unique_short_name = "accounting"
  region            = local.aws_region
  filter_pattern    = "{ $.level = \"ERROR\" }"
}

module "debug_accounting_cloudwatch_error_log_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.accounting_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  unique_short_name         = "accounting"
  message_retention_seconds = 172800 # 2 days
}

module "accounting_error_log_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = "accounting_logs_errors"

  unique_short_name = "accounting"
  sns_topic_arn     = module.accounting_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  python_runtime    = "python3.13"
}

module "ml" {
  source = "./ml"

  aws_region = local.aws_region
  account_id = local.account_id

  is_production   = var.is_production
  obi_backup_plan = "obi_plan"

  ml_secrets_arn = local.ml_secrets_arn

  vpc_id                         = local.vpc_id
  vpc_cidr_block                 = local.vpc_cidr_block
  route_table_private_subnets_id = local.route_table_private_subnets_id

  neuroagent_docker_image_url = var.neuroagent_docker_image_url
  neuroagent_bucket_name      = var.ml_neuroagent_bucket_name

  primary_domain = local.primary_domain

  # NEW PRIVATE ALB
  generic_private_alb_listener_arn      = local.private_alb_https_listener_arn
  generic_private_alb_security_group_id = data.terraform_remote_state.common.outputs.generic_private_alb_security_group_id

  github_oidc_provider_arn = module.github_oidc_provider.oidc_provider_arn

  github_repos = ["openbraininstitute/neuroagent"]
}

# NOTE: The Nexus service has been fully decommissioned.
# The purpose of this module is to maintain the data backups in S3 Glacier.
# DO NOT DELETE: Deleting this module will also delete the S3 buckets and all backups.
module "nexus" {
  source = "./nexus"

  nexus_obp_bucket_name         = var.nexus_obp_bucket_name
  nexus_ship_bucket_name        = var.nexus_ship_bucket_name
  nexus_openscience_bucket_name = var.nexus_openscience_bucket_name
}

module "cells_svc" {
  source = "./cells_svc"

  aws_region = local.aws_region

  vpc_id         = local.vpc_id
  vpc_cidr_block = local.vpc_cidr_block

  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_private_subnets_id = local.route_table_private_subnets_id

  cell_svc_perf_bucket_name = aws_s3_bucket.sbo-cell-svc-perf-test.id

  aws_coreservices_ssh_key_id = module.coreservices_key.key_pair_id

  root_path    = "/api/circuit"
  keycloak_url = "https://${local.primary_domain}/auth/realms/SBO/"

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id

  cell_svc_docker_image_url = var.cell_svc_docker_image_url
}

module "small_scale_simulator" {
  source = "./small_scale_simulator"

  aws_region                 = local.aws_region
  vpc_id                     = local.vpc_id
  alb_listener_arn           = local.private_alb_https_listener_arn
  alb_listener_rule_priority = 760
  internet_access_route_id   = local.route_table_private_subnets_id

  secrets_arn = local.small_scale_simulator_secrets_arn

  api_docker_image_url    = var.small_scale_simulator_api_docker_image_url
  worker_docker_image_url = var.small_scale_simulator_worker_docker_image_url

  base_path    = "/api/small-scale-simulator"
  cors_origins = local.core_web_app_origins

  accounting_base_url = "https://${local.primary_domain}${var.accounting_svc_base_path}"
  entitycore_url      = "https://${local.primary_domain}/api/entitycore"
  keycloak_server_url = "https://${local.primary_domain}/auth/"

  api_task_size = var.small_scale_simulator_api_task_size

  daemon_workers = var.small_scale_simulator_daemon_workers
  batch_workers  = var.small_scale_simulator_batch_workers
}

module "github_ami_build_role" {
  source                   = "./github_ami_build_role"
  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  github_oidc_provider_arn = module.github_oidc_provider.oidc_provider_arn
  repo_name                = "machine-images"
  bucket_name              = var.infrastructureassets_bucket
}

module "notebook_service" {
  source = "./notebook_service"

  aws_region                 = local.aws_region
  vpc_id                     = local.vpc_id
  private_alb_listener_arn   = local.private_alb_https_listener_arn
  alb_listener_rule_priority = 755
  internet_access_route_id   = local.route_table_private_subnets_id
  ecs_cidr_block_a           = "10.0.2.192/27"
  ecs_cidr_block_b           = "10.0.2.224/27"

  cors_allowed_origins      = var.notebook_service_cors_allowed_origins
  kubernetes_thread_enabled = var.notebook_service_k8s_thread_enabled

  kubernetes_thread_check_interval = 15

  jupyterhub_eks_shared_home_dirs_efs_id = var.jupyterhub_eks_shared_home_dirs_efs_id

  task_size = {
    cpu    = 512
    memory = 1024
  }

  docker_image_url = var.notebook_service_docker_image_url
  environment      = var.deployment_env

  base_path = "/api/notebook_service"

  accounting_base_url          = "https://${local.primary_domain}${var.accounting_svc_base_path}"
  keycloak_url                 = "https://${local.primary_domain}/auth/realms/SBO"
  notebook_service_bucket_name = var.notebook_service_bucket_name

  accounting_enabled  = var.notebook_service_accounting_enabled
  hub_on_eks_full_url = var.notebook_hub_on_eks_full_url
  secrets_arn         = local.notebook_service_secrets_arn

  acounting_db_athena_connector_name = module.accounting_svc.athena_data_catalog_name
}

module "github_notebook_service_ecs_redeploy_role" {
  source = "./github_ecs_redeploy_role"

  # for now we only want such a redeploy role in staging
  count = var.is_staging ? 1 : 0

  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  repo_name                = "notebook-service"
  ecs_cluster_name         = module.notebook_service.ecs_cluster_name
  ecs_service_name         = module.notebook_service.ecs_service_name
  ecs_task_definition_name = module.notebook_service.ecs_task_definition_name
  # The ARN of the generated role is needed in GH and is part of the outputs.
}


module "hpc" {
  source = "./hpc"

  aws_region                                 = local.aws_region
  account_id                                 = local.account_id
  obp_vpc_id                                 = local.vpc_id
  obp_vpc_default_sg_id                      = local.vpc_default_sg_id
  sbo_billing                                = "hpc"
  slurm_mysql_admin_username                 = "slurm_admin"
  create_compute_instances                   = false
  num_compute_instances                      = 0
  create_slurmdb                             = false # TODO-SLURMDB: re-enable when redeploying the cluster
  compute_instance_type                      = "m7g.medium"
  create_jumphost                            = false
  compute_nat_access                         = false
  compute_subnet_count                       = 16
  av_zone_suffixes                           = var.hpc_av_zone_suffixes
  peering_route_tables                       = [local.route_table_private_subnets_id, local.route_table_public_id]
  lambda_subnet_cidr                         = "10.0.16.0/24"
  is_staging                                 = var.is_staging
  is_production                              = var.is_production
  aws_endpoints_subnet_cidr                  = module.networking.endpoints_subnet_cidr
  endpoints_route_table_id                   = local.route_table_private_subnets_id
  hpc_slurm_secrets_arn                      = local.hpc_slurm_secrets_arn
  hpc_resource_provisioner_container_version = var.hpc_resource_provisioner_container_version
  data_bucket                                = var.hpc_resource_provisioner_data_bucket
  containers_bucket                          = var.hpc_resource_provisioner_containers_bucket
  scratch_bucket                             = var.hpc_resource_provisioner_scratch_bucket
  scratch_bucket_arn                         = var.hpc_resource_provisioner_scratch_bucket_arn
  private_alb_https_listener_arn             = local.private_alb_https_listener_arn
  infrastructureassets_bucket_name           = var.infrastructureassets_bucket
  pcluster_ami_id                            = var.pcluster_ami_id
}

module "static-server" {
  source = "./static-server"

  aws_region                 = local.aws_region
  account_id                 = local.account_id
  vpc_id                     = local.vpc_id
  public_subnet_ids          = [data.terraform_remote_state.common.outputs.public_a_subnet_id, data.terraform_remote_state.common.outputs.public_b_subnet_id]
  domain_name                = local.primary_domain
  static_content_bucket_name = local.primary_domain
  alb_listener_arn           = local.private_alb_https_listener_arn
  alb_listener_rule_priority = 600
}

module "core_webapp_main" {
  source = "./core_webapp"

  key                           = "main"
  log_group_name                = "core_webapp_main"
  vpc_id                        = local.vpc_id
  subnet_cidr_block             = "10.0.21.0/28"
  alb_listener_arn              = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  alb_listener_rule_priority    = 1000
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  aws_region                    = local.aws_region
  docker_image_url              = var.core_web_app_docker_image_url
  route_table_id                = local.route_table_private_subnets_id
  vpc_cidr_block                = local.vpc_cidr_block
  secrets_arn                   = local.core_webapp_secrets_arn
  accounting_base_url           = "https://${local.primary_domain}${var.accounting_svc_base_path}"
  s3_bucket_name                = var.core_webapp_s3_bucket_name
  s3_bucket_allowed_origins     = ["https://${local.primary_domain}", "https://${join(".", ["cdn", trimprefix(local.primary_domain, "www.")])}"]

  # remove 'www.' from local.primary_domain and prepend 'cdn'. ie: cdn.openbraininstitute.org
  cloudfront_aliases         = [join(".", ["cdn", trimprefix(local.primary_domain, "www.")])]
  cloudfront_certificate_arn = local.cloudfront_certificate_arn

  env_NEXTAUTH_URL    = "https://${local.primary_domain}/api/auth"
  env_KEYCLOAK_ISSUER = "https://${local.primary_domain}/auth/realms/SBO"
}

module "core_webapp_dev" {
  source = "./core_webapp"

  count = var.is_staging ? 1 : 0

  key               = "dev"
  log_group_name    = "core_webapp_dev"
  vpc_id            = local.vpc_id
  subnet_cidr_block = "10.0.21.32/28"
  alb_listener_arn  = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  # The following priority has to be higher (lower number)
  # than the priority of the main core-web-app listener rule.
  hostname                      = "dev.openbraininstitute.org"
  alb_listener_rule_priority    = 980
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  aws_region                    = local.aws_region
  docker_image_url              = var.core_web_app_dev_docker_image_url
  route_table_id                = local.route_table_private_subnets_id
  vpc_cidr_block                = local.vpc_cidr_block
  secrets_arn                   = local.core_webapp_secrets_arn
  accounting_base_url           = "https://${local.primary_domain}${var.accounting_svc_base_path}"

  // These are not used in dev
  s3_bucket_name            = var.core_webapp_s3_bucket_name
  s3_bucket_allowed_origins = ["https://dev.openbraininstitute.org"]

  sbo_billing_tag = "core_webapp_dev"

  env_NEXTAUTH_URL    = "https://dev.openbraininstitute.org/api/auth"
  env_KEYCLOAK_ISSUER = "https://${local.primary_domain}/auth/realms/SBO"
}

module "core_webapp_preview" {
  source = "./core_webapp"

  count = var.is_staging ? 1 : 0

  key               = "preview"
  log_group_name    = "core_webapp_preview"
  vpc_id            = local.vpc_id
  subnet_cidr_block = "10.0.21.48/28"
  alb_listener_arn  = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  # The following priority has to be higher (lower number)
  # than the priority of the main core-web-app listener rule.
  hostname                      = "preview.openbraininstitute.org"
  alb_listener_rule_priority    = 981
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  aws_region                    = local.aws_region
  docker_image_url              = var.core_web_app_preview_docker_image_url
  route_table_id                = local.route_table_private_subnets_id
  vpc_cidr_block                = local.vpc_cidr_block
  secrets_arn                   = local.core_webapp_secrets_arn
  accounting_base_url           = "https://${local.primary_domain}${var.accounting_svc_base_path}"

  // These are not used in preview
  s3_bucket_name            = var.core_webapp_s3_bucket_name
  s3_bucket_allowed_origins = ["https://preview.openbraininstitute.org"]

  sbo_billing_tag = "core_webapp_preview"

  env_NEXTAUTH_URL    = "https://preview.openbraininstitute.org/api/auth"
  env_KEYCLOAK_ISSUER = "https://${local.primary_domain}/auth/realms/SBO"
}

module "github_core_webapp_main_ecs_redeploy_role" {
  source = "./github_ecs_redeploy_role"

  # for now we only want such a redeploy role in staging
  count = var.is_staging ? 1 : 0

  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  repo_name                = "core-web-app"
  ecs_cluster_name         = module.core_webapp_main.ecs_cluster_name
  ecs_service_name         = module.core_webapp_main.ecs_service_name
  ecs_task_definition_name = module.core_webapp_main.ecs_task_definition_name
  # The ARN of the generated role is needed in GH and is part of the outputs.
}

module "github_core_webapp_dev_ecs_redeploy_role" {
  source = "./github_ecs_redeploy_role"

  # for now we only want such a redeploy role in staging
  count = var.is_staging ? 1 : 0

  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  repo_name                = "core-web-app"
  ecs_cluster_name         = module.core_webapp_dev[0].ecs_cluster_name
  ecs_service_name         = module.core_webapp_dev[0].ecs_service_name
  ecs_task_definition_name = module.core_webapp_dev[0].ecs_task_definition_name
  # The ARN of the generated role is needed in GH and is part of the outputs.
}

module "github_core_webapp_preview_ecs_redeploy_role" {
  source = "./github_ecs_redeploy_role"

  # for now we only want such a redeploy role in staging
  count = var.is_staging ? 1 : 0

  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  repo_name                = "core-web-app"
  ecs_cluster_name         = module.core_webapp_preview[0].ecs_cluster_name
  ecs_service_name         = module.core_webapp_preview[0].ecs_service_name
  ecs_task_definition_name = module.core_webapp_preview[0].ecs_task_definition_name
  # The ARN of the generated role is needed in GH and is part of the outputs.
}

module "doi_redirect" {
  source = "./redirect_link"

  listener_rule_priority         = 50
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
}

module "accounting_svc" {
  source = "./accounting_svc"

  aws_region                     = local.aws_region
  vpc_id                         = local.vpc_id
  private_alb_listener_arn       = local.private_alb_https_listener_arn
  internet_access_route_id       = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks  = [local.vpc_cidr_block]
  docker_image_url               = var.accounting_svc_docker_image_url
  accounting_service_secrets_arn = local.accounting_service_secrets_arn

  root_path = var.accounting_svc_base_path

  accounting_db_ro_secret_arn = local.accounting_db_ro_secret_arn
  aws_deployment_env          = var.deployment_env
}

module "entitycore_svc" {
  source = "./entitycore_svc"

  aws_region                    = local.aws_region
  vpc_id                        = local.vpc_id
  private_alb_listener_arn      = local.private_alb_https_listener_arn
  internet_access_route_id      = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  cors_origins = local.core_web_app_origins

  entitycore_service_secrets_arn = local.entitycore_service_secrets_arn

  root_path = "/api/entitycore"

  # use staging keycloak url in sandboxes
  keycloak_url = (var.is_staging || var.is_production) ? (
    "https://${local.primary_domain}/auth/realms/SBO/"
    ) : (
    "https://staging.openbraininstitute.org/auth/realms/SBO/"
  )

  s3_bucket_allowed_origins = var.entitycore_svc_s3_bucket_allowed_origins
  aws_s3_internal_bucket    = var.entitycore_svc_aws_s3_internal_bucket
  aws_s3_internal_region    = var.entitycore_svc_aws_s3_internal_region
  aws_s3_open_bucket        = var.entitycore_svc_aws_s3_open_bucket
  aws_s3_open_region        = var.entitycore_svc_aws_s3_open_region


  image_url = var.entitycore_svc_image_url

  db_name     = "entitycore"
  db_username = "entitycore"

  obi_backup_plan = "obi_plan"

  api_asset_post_max_size = "524288000" # 500 * 1024**2
}
module "auth_manager" {
  source = "./auth-manager"

  number_of_containers = var.is_staging ? 1 : 0

  aws_region                    = local.aws_region
  vpc_id                        = local.vpc_id
  private_alb_listener_arn      = local.private_alb_https_listener_arn
  internet_access_route_id      = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  route_table_id                = local.route_table_private_subnets_id

  cors_origins = local.core_web_app_origins

  auth_manager_secrets_arn = local.auth_manager_secrets_arn

  root_path = "/api/auth-manager"

  primary_domain = local.primary_domain

  image_url = var.auth_manager_svc_image_url

  keycloak_client_uuid = var.keycloak_client_uuid
  keycloak_client_id   = var.keycloak_client_id

  db_name     = "auth_manager"
  db_username = "auth_manager"

  obi_backup_plan = "obi_plan"
}

module "obi_one" {
  # TODO: remove after the deployment for deletion
  source     = "./obi_one"
  aws_region = local.aws_region
}

module "obi_one_v2" {
  source = "./obi_one_v2"

  aws_region = local.aws_region

  vpc_id         = local.vpc_id
  vpc_cidr_block = local.vpc_cidr_block

  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_private_subnets_id = local.route_table_private_subnets_id

  aws_coreservices_ssh_key_id = module.coreservices_key.key_pair_id

  ec2_instance_type = var.obi_one_v2_ec2_instance_type
  ecs_task_size     = var.obi_one_v2_ecs_task_size

  root_path      = "/api/obi-one"
  container_port = 8000
  host_port      = 8000

  keycloak_url   = "https://${local.primary_domain}/auth/realms/SBO/"
  entitycore_url = "https://${local.primary_domain}/api/entitycore"

  cors_origins = local.core_web_app_origins

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  amazon_linux_ecs_ami_id = data.aws_ami.amazon_linux_2_ecs.id

  docker_image_url = var.obi_one_v2_docker_image_url

  mount_base_dir = "/data" # used to prefix both volume_host_path and volume_container_path
  mount_buckets = [
    {
      bucket_name           = var.entitycore_svc_aws_s3_internal_bucket
      bucket_region         = var.entitycore_svc_aws_s3_internal_region
      bucket_prefix         = "public/" # must end with / if not empty
      volume_name           = "public-data"
      volume_host_path      = "/aws_s3_internal/public/"
      volume_container_path = "/aws_s3_internal/public/"
      mount_extra_options   = ""
    },
    {
      bucket_name           = var.entitycore_svc_aws_s3_open_bucket
      bucket_region         = var.entitycore_svc_aws_s3_open_region
      bucket_prefix         = "" # must end with / if not empty
      volume_name           = "open-data"
      volume_host_path      = "/aws_s3_open/"
      volume_container_path = "/aws_s3_open/"
      mount_extra_options   = "--no-sign-request"
    },
  ]
}

module "obi_generative_gui" {
  aws_region = local.aws_region
  source     = "./obi_generative_gui"
}

module "kg_inference_api" {
  source = "./kg-inference-api"
}

module "thumbnail_generation_api" {
  source = "./thumbnail-generation-api"

  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_id                 = local.route_table_private_subnets_id
  vpc_cidr_block                 = local.vpc_cidr_block
  vpc_id                         = local.vpc_id

  aws_region                                = local.aws_region
  allowed_source_ip_cidr_blocks             = ["0.0.0.0/0"]
  thumbnail_generation_api_docker_image_url = var.thumbnail_generation_api_docker_image_url
  thumbnail_generation_api_base_path        = "/api/thumbnail-generation"
  thumbnail_generation_api_log_group_name   = "thumbnail_generation_api"
  thumbnail_generation_api_cors_origins     = local.core_web_app_origins
  entitycore_url                            = "https://${local.primary_domain}/api/entitycore"
}

module "virtual_lab_manager" {
  source = "./virtual-lab-manager"

  vpc_id                         = local.vpc_id
  aws_region                     = local.aws_region
  account_id                     = local.account_id
  vpc_cidr_block                 = local.vpc_cidr_block
  allowed_source_ip_cidr_blocks  = [local.vpc_cidr_block]
  private_lb_listener_https_arn  = local.private_alb_https_listener_arn
  route_table_private_subnets_id = local.route_table_private_subnets_id

  invite_link = "https://${local.primary_domain}/app"
  mail_from   = "no-reply@${local.email_domain_name}"

  db_multi_az = var.is_production

  virtual_lab_manager_postgres_db   = "vlm"
  virtual_lab_manager_postgres_user = "vlm_user"

  log_group_name = var.virtual_lab_manager_log_group_name

  virtual_lab_manager_docker_image_url = var.virtual_lab_manager_docker_image_url

  keycloak_server_url = "https://${local.primary_domain}/auth/"

  virtual_lab_manager_secrets_arn = local.virtual_lab_manager_secrets_arn

  task_size                = var.virtual_lab_manager_task_size
  ecs_number_of_containers = var.virtual_lab_manager_ecs_number_of_containers

  virtual_lab_manager_depoloyment_env = "production"

  virtual_lab_manager_invite_expiration = "7"

  virtual_lab_manager_mail_username = module.ses_user_virtuallab.access_key_id
  virtual_lab_manager_mail_server   = "email-smtp.${local.aws_region}.amazonaws.com"
  virtual_lab_manager_base_path     = var.virtual_lab_manager_base_path
  virtual_lab_manager_mail_password = module.ses_user_virtuallab.ses_smtp_password_v4

  virtual_lab_manager_mail_port = "587"

  virtual_lab_manager_mail_starttls   = "True"
  virtual_lab_manager_use_credentials = "True"
  virtual_lab_manager_cors_origins    = local.core_web_app_origins

  virtual_lab_manager_admin_base_path      = "{}/app/virtual-lab/lab/{}/admin?panel=billing"
  virtual_lab_manager_deployment_namespace = "https://${local.primary_domain}"

  accounting_base_url = "https://${local.primary_domain}${var.accounting_svc_base_path}"

  virtual_lab_manager_db_ro_secret_arn = local.virtual_lab_manager_db_ro_secret_arn
  aws_deployment_env                   = var.deployment_env
}

module "launch_server" {
  # TODO: remove after the deployment for deletion
  source     = "./launch_server"
  aws_region = local.aws_region
}

module "public_data_efs" {
  source = "./public_data_efs"

  count = var.is_staging ? 1 : 0

  vpc_id                  = local.vpc_id
  vpc_cidr_block          = local.vpc_cidr_block
  access_point_subnet_ids = module.launch_system[0].executor_network_ids
  account_id              = local.account_id
  aws_region              = local.aws_region

  entitycore_internal_bucket = var.entitycore_svc_aws_s3_internal_bucket
  entitycore_internal_region = var.entitycore_svc_aws_s3_internal_region
  open_data_bucket           = var.entitycore_svc_aws_s3_open_bucket
  open_data_region           = var.entitycore_svc_aws_s3_open_region
}

module "launch_system" {
  source = "./launch_system"

  count = var.is_staging ? 1 : 0

  aws_region                    = local.aws_region
  vpc_id                        = local.vpc_id
  account_id                    = local.account_id
  private_alb_listener_arn      = local.private_alb_https_listener_arn
  internet_access_route_id      = local.route_table_private_subnets_id
  vpc_cidr_block                = local.vpc_cidr_block
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  # allowed_source_ip_cidr_blocks = [local.vpc_cidr_block]

  secrets_arn  = local.launch_system_secrets_arn
  cors_origins = local.core_web_app_origins

  deployment_env = var.deployment_env

  ec_node_type = "cache.t4g.micro" # for redis

  db_instance_class    = "db.t4g.micro"
  db_allocated_storage = 50

  db_name         = "launch"
  db_username     = "launch"
  obi_backup_plan = "obi_plan"

  api_image_url              = "985539765147.dkr.ecr.us-east-1.amazonaws.com/launch-system/api:2025.11.3"
  orchestrator_image_url     = "985539765147.dkr.ecr.us-east-1.amazonaws.com/launch-system/orchestrator:2025.11.3"
  default_executor_image_url = "985539765147.dkr.ecr.us-east-1.amazonaws.com/launch-system/default-executor:2025.11.3"

  api_task_size          = var.launch_system_api_task_size
  executor_task_size     = var.launch_system_executor_task_size
  orchestrator_task_size = var.launch_system_orchestrator_task_size

  orchestrator_num_workers = var.launch_system_orchestrator_num_workers
  queues                   = ["high", "medium", "low"]

  root_path    = "/api/launch-system"
  keycloak_url = "https://${local.primary_domain}/auth/realms/SBO/"

  token_lifetime_extension_interval = 0

  launch_system_api_url = "https://${local.primary_domain}/api/launch-system"
  entitycore_url        = "https://${local.primary_domain}/api/entitycore"
  accounting_url        = "https://${local.primary_domain}/api/accounting"
  auth_manager_url      = "https://${local.primary_domain}/api/auth-manager"

  az_region          = "eastus"
  keycloak_client_id = "obi-entitysdk-auth"

  public_launch_data_efs_id            = module.public_data_efs[0].public_launch_data_efs_id
  internal_public_data_access_point_id = module.public_data_efs[0].internal_public_data_access_point_id
  open_public_data_access_point_id     = module.public_data_efs[0].open_public_data_access_point_id
}



module "dashboards" {
  source = "./dashboards"

  aws_region = local.aws_region

  private_load_balancer_id = local.private_alb_https_listener_arn
  private_load_balancer_target_suffixes = merge(
    {
      "AccountingService"   = module.accounting_svc.private_lb_rule_suffix
      "CoreWebAppMain"      = module.core_webapp_main.private_lb_rule_suffix
      "EntityCoreService"   = module.entitycore_svc.private_lb_rule_suffix
      "KeyCloak"            = module.cs.private_keycloak_lb_rule_suffix
      "SmallScaleSimulator" = module.small_scale_simulator.private_lb_rule_suffix
      "SonataCellService"   = module.cells_svc.private_lb_rule_suffix
      "ThumbnailGenerator"  = module.thumbnail_generation_api.private_lb_rule_suffix
      "VLabManager"         = module.virtual_lab_manager.private_arn_suffix
      "ObiOneV2"            = module.obi_one_v2.private_lb_rule_suffix
    },
    var.is_staging ? {
      "CoreWebAppDev"     = module.core_webapp_dev[0].private_lb_rule_suffix
      "CoreWebAppPreview" = module.core_webapp_preview[0].private_lb_rule_suffix
      "LaunchSystem"      = module.launch_system[0].private_lb_rule_suffix
    } : {}
  )
}


module "ses_user_virtuallab" {
  source = "./ses_user"

  user_name = "ses-smtp-user.obp.virtuallabs"
}
