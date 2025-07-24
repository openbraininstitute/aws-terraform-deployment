locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id

  private_alb_https_listener_arn = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  route_table_private_subnets_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
  route_table_public_id          = data.terraform_remote_state.common.outputs.route_table_public_id

  public_nlb_sg_id = data.terraform_remote_state.common.outputs.public_nlb_sg_id
  nat_gateway_id   = data.terraform_remote_state.common.outputs.nat_gateway_id

  vpc_cidr_block    = data.terraform_remote_state.common.outputs.vpc_cidr_block
  vpc_default_sg_id = data.terraform_remote_state.common.outputs.vpc_default_sg_id

  primary_domain    = data.terraform_remote_state.common.outputs.primary_domain
  email_domain_name = data.terraform_remote_state.common.outputs.email_domain_name

  virtual_lab_manager_secrets_arn  = data.terraform_remote_state.common.outputs.virtual_lab_manager_secrets_arn
  keycloak_secrets_arn             = data.terraform_remote_state.common.outputs.keycloak_secrets_arn
  jupyterhub_secrets_arn           = data.terraform_remote_state.common.outputs.jupyterhub_secrets_arn
  core_webapp_secrets_arn          = data.terraform_remote_state.common.outputs.core_webapp_secrets_arn
  ml_secrets_arn                   = data.terraform_remote_state.common.outputs.ml_secrets_arn
  bluenaas_service_secrets_arn     = data.terraform_remote_state.common.outputs.bluenaas_service_secrets_arn
  accounting_service_secrets_arn   = data.terraform_remote_state.common.outputs.accounting_service_secrets_arn
  entitycore_service_secrets_arn   = data.terraform_remote_state.common.outputs.entitycore_service_secrets_arn
  hpc_slurm_secrets_arn            = data.terraform_remote_state.common.outputs.hpc_slurm_secrets_arn
  nexus_secrets_arn                = data.terraform_remote_state.common.outputs.nexus_secrets_arn
  workflow_service_secrets_arn     = data.terraform_remote_state.common.outputs.workflow_service_secrets_arn
  dockerhub_bbpbuildbot_secret_arn = data.terraform_remote_state.common.outputs.dockerhub_bbpbuildbot_secret_arn
  dockerhub_bbpbuildbot_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_bbpbuildbot_policy_arn

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

  vpc_id                         = local.vpc_id
  route_table_private_subnets_id = local.route_table_private_subnets_id
  db_instance_class              = "db.t3.micro"
  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  keycloak_secrets_arn           = local.keycloak_secrets_arn
  keycloak_task_size             = var.keycloak_task_size
  aws_coreservices_ssh_key_id    = module.coreservices_key.key_pair_id

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

module "deployments_sns_topic" {
  source = "./deployments_sns_topic"
}

module "deployments_sns_to_teams" {
  source = "./sns_lambda_to_teams"

  unique_name          = "aws_deployments" # to make sure certain roles and secrets have a unique name
  sns_topic_arn        = module.deployments_sns_topic.sns_topic_arn
  python_script_name   = "aws_deployments_sns_to_teams.py"
  python_function_name = "handle_deployment_event"
  handler              = "aws_deployments_sns_to_teams.handle_deployment_event"
  python_runtime       = "python3.11"

  secret_recovery_window_in_days = 7
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

  dockerhub_credentials_arn = local.dockerhub_bbpbuildbot_secret_arn
  agent_image_tag           = "neuroagent-v0.7.1"

  neuroagent_bucket_name = var.ml_neuroagent_bucket_name
  nexus_domain_name      = module.nexus.nexus_domain_name
  primary_domain         = local.primary_domain

  # OLD PRIVATE ALB
  private_alb_security_group_id = data.terraform_remote_state.common.outputs.private_alb_security_group_id
  private_alb_listener_arn      = data.terraform_remote_state.common.outputs.private_alb_listener_3000_arn
  private_alb_dns               = data.terraform_remote_state.common.outputs.private_alb_dns_name

  # NEW PRIVATE ALB
  generic_private_alb_listener_arn      = local.private_alb_https_listener_arn
  generic_private_alb_security_group_id = data.terraform_remote_state.common.outputs.generic_private_alb_security_group_id

  github_oidc_provider_arn = module.github_oidc_provider.oidc_provider_arn

  github_repos = ["openbraininstitute/neuroagent"]
}

module "nexus" {
  source = "./nexus"

  providers = {
    ec     = ec
    ec.ec2 = ec.ec2
  }

  aws_region         = local.aws_region
  account_id         = local.account_id
  vpc_id             = local.vpc_id
  domain_name        = var.nexus_domain_name # TODO move nexus to local.primary_domain
  dockerhub_password = var.nise_dockerhub_password
  nexus_secrets_arn  = local.nexus_secrets_arn
  nexus_az_letter_id = var.nexus_az_letter_id

  nat_gateway_id = local.nat_gateway_id

  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  nexus_obp_bucket_name         = var.nexus_obp_bucket_name
  nexus_ship_bucket_name        = var.nexus_ship_bucket_name
  nexus_openscience_bucket_name = var.nexus_openscience_bucket_name

  private_lb_listener_https_arn = local.private_alb_https_listener_arn

  is_production = var.is_production

  is_nexus_openscience_running = var.is_nexus_openscience_running
  is_nexus_obp_running         = var.is_nexus_obp_running
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

  # TODO Clone from bluenaas_svc before it is retired
  secrets_arn = local.bluenaas_service_secrets_arn

  api_docker_image_url    = var.small_scale_simulator_api_docker_image_url
  worker_docker_image_url = var.small_scale_simulator_worker_docker_image_url

  base_path = "/api/small-scale-simulator"
  cors_origins = concat(
    ["https://${local.primary_domain}"],
    var.is_staging ? ["http://localhost:3000"] : []
  )

  nexus_delta_uri = "https://${module.nexus.nexus_domain_name}/api/nexus/v1"

  accounting_base_url = "https://${local.primary_domain}${var.accounting_svc_base_path}"
  entitycore_url      = "https://${local.primary_domain}/api/entitycore"
  keycloak_server_url = "https://${local.primary_domain}/auth/"

  api_task_size = var.small_scale_simulator_api_task_size
  workers       = var.small_scale_simulator_workers
}

module "github_ami_build_role" {
  source                   = "./github_ami_build_role"
  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  github_oidc_provider_arn = module.github_oidc_provider.oidc_provider_arn
  repo_name                = "machine-images"
  bucket_name              = var.sbo_infrastructureassets_bucket
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

  secret_recovery_window_in_days = 7

  task_size = {
    cpu    = 512
    memory = 1024
  }

  docker_image_url = var.notebook_service_docker_image_url

  base_path = "/api/notebook_service"

  accounting_base_url = "https://${local.primary_domain}${var.accounting_svc_base_path}"
  keycloak_server_url = "https://${local.primary_domain}/auth/"
  keycloak_realm_name = "SBO"
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
  av_zone_suffixes                           = ["a"]
  peering_route_tables                       = [local.route_table_private_subnets_id, local.route_table_public_id]
  lambda_subnet_cidr                         = "10.0.16.0/24"
  is_production                              = var.is_production
  aws_endpoints_subnet_cidr                  = module.networking.endpoints_subnet_cidr
  endpoints_route_table_id                   = local.route_table_private_subnets_id
  hpc_slurm_secrets_arn                      = local.hpc_slurm_secrets_arn
  hpc_resource_provisioner_container_version = var.hpc_resource_provisioner_container_version
  sbo_nexusdata_bucket                       = var.hpc_resource_provisioner_sbo_nexusdata_bucket
  containers_bucket                          = var.hpc_resource_provisioner_containers_bucket
  scratch_bucket                             = var.hpc_resource_provisioner_scratch_bucket
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

  env_NEXTAUTH_URL                          = "https://${local.primary_domain}/api/auth"
  env_KEYCLOAK_ISSUER                       = "https://${local.primary_domain}/auth/realms/SBO"
  env_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY    = "pk_test_51QjjHBKGUR5u3ofLgNUOpljnvy27UTTpkhwgsLiwK9xlNjnR7CZfiMjtZWMjgN7GW3eDyzMJ7Z1pIqC9LiwkfQRX00ebb5c9XI"
  env_NEXT_PUBLIC_BBS_ML_PRIVATE_BASE_URL   = "http://${data.terraform_remote_state.common.outputs.private_alb_dns_name}:3000/api/literature"
  env_NEXT_PUBLIC_DEPLOYMENT_ENV            = var.core_web_app_deployment_env
  env_NEXT_PUBLIC_MATOMO_SITE_ID            = var.core_web_app_next_public_matomo_site_id
  env_NEXT_PUBLIC_MATOMO_CDN_URL            = "https://cdn.matomo.cloud/openbraininstitute.matomo.cloud"
  env_NEXT_PUBLIC_MATOMO_URL                = "https://openbraininstitute.matomo.cloud"
  env_NEXT_PUBLIC_ENABLE_RUN_NOTEBOOK       = var.is_staging ? "true" : "false"
  env_NEXT_PUBLIC_NOTEBOOK_SERVICE_BASE_URL = "https://${local.primary_domain}/api/notebook_service"
}

module "core_webapp_next" {
  source = "./core_webapp"

  count = var.is_staging ? 1 : 0

  key               = "next"
  log_group_name    = "core_webapp_next"
  vpc_id            = local.vpc_id
  subnet_cidr_block = "10.0.21.16/28"
  alb_listener_arn  = data.terraform_remote_state.common.outputs.private_alb_https_listener_arn
  # The following priority has to be higher (lower number)
  # than the priority of the main core-web-app listener rule.
  hostname                      = "next.staging.openbraininstitute.org"
  alb_listener_rule_priority    = 980
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]
  aws_region                    = local.aws_region
  docker_image_url              = var.core_web_app_next_docker_image_url
  route_table_id                = local.route_table_private_subnets_id
  vpc_cidr_block                = local.vpc_cidr_block
  secrets_arn                   = local.core_webapp_secrets_arn
  accounting_base_url           = "https://${local.primary_domain}${var.accounting_svc_base_path}"

  env_NEXTAUTH_URL                          = "https://next.staging.openbraininstitute.org/api/auth"
  env_KEYCLOAK_ISSUER                       = "https://${local.primary_domain}/auth/realms/SBO"
  env_NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY    = "pk_test_51QjjHBKGUR5u3ofLgNUOpljnvy27UTTpkhwgsLiwK9xlNjnR7CZfiMjtZWMjgN7GW3eDyzMJ7Z1pIqC9LiwkfQRX00ebb5c9XI"
  env_NEXT_PUBLIC_BBS_ML_PRIVATE_BASE_URL   = "http://${data.terraform_remote_state.common.outputs.private_alb_dns_name}:3000/api/literature"
  env_NEXT_PUBLIC_DEPLOYMENT_ENV            = var.core_web_app_deployment_env
  env_NEXT_PUBLIC_MATOMO_SITE_ID            = var.core_web_app_next_public_matomo_site_id
  env_NEXT_PUBLIC_MATOMO_CDN_URL            = "https://cdn.matomo.cloud/openbraininstitute.matomo.cloud"
  env_NEXT_PUBLIC_MATOMO_URL                = "https://openbraininstitute.matomo.cloud"
  env_NEXT_PUBLIC_ENABLE_RUN_NOTEBOOK       = var.is_staging ? "true" : "false"
  env_NEXT_PUBLIC_NOTEBOOK_SERVICE_BASE_URL = "https://${local.primary_domain}/api/notebook_service"
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

module "github_core_webapp_next_ecs_redeploy_role" {
  source = "./github_ecs_redeploy_role"

  # for now we only want such a redeploy role in staging
  count = var.is_staging ? 1 : 0

  account_id               = local.account_id
  aws_region               = local.aws_region
  github_organisation      = local.github_organisation
  repo_name                = "core-web-app"
  ecs_cluster_name         = module.core_webapp_next[0].ecs_cluster_name
  ecs_service_name         = module.core_webapp_next[0].ecs_service_name
  ecs_task_definition_name = module.core_webapp_next[0].ecs_task_definition_name
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
}

module "entitycore_svc" {
  source = "./entitycore_svc"

  aws_region                    = local.aws_region
  vpc_id                        = local.vpc_id
  private_alb_listener_arn      = local.private_alb_https_listener_arn
  internet_access_route_id      = local.route_table_private_subnets_id
  allowed_source_ip_cidr_blocks = ["0.0.0.0/0"]

  entitycore_service_secrets_arn = local.entitycore_service_secrets_arn

  root_path = "/api/entitycore"

  # use staging keycloak url in sandboxes
  keycloak_url = (var.is_staging || var.is_production) ? (
    "https://${local.primary_domain}/auth/realms/SBO/"
    ) : (
    "https://staging.openbraininstitute.org/auth/realms/SBO/"
  )

  s3_bucket_name            = var.entitycore_svc_s3_bucket_name # for backward compatibility
  s3_bucket_allowed_origins = var.entitycore_svc_s3_bucket_allowed_origins
  aws_s3_internal_bucket    = var.entitycore_svc_aws_s3_internal_bucket
  aws_s3_internal_region    = var.entitycore_svc_aws_s3_internal_region
  aws_s3_open_bucket        = var.entitycore_svc_aws_s3_open_bucket
  aws_s3_open_region        = var.entitycore_svc_aws_s3_open_region


  image_url = var.entitycore_svc_image_url

  db_name     = "entitycore"
  db_username = "entitycore"

  obi_backup_plan = "obi_plan"
}

module "obi_one" {
  source = "./obi_one"

  aws_region               = local.aws_region
  vpc_id                   = local.vpc_id
  private_alb_listener_arn = local.private_alb_https_listener_arn
  internet_access_route_id = local.route_table_private_subnets_id

  root_path = "/api/obi-one"

  container_port = 8000
  host_port      = 8000

  keycloak_url     = "https://${local.primary_domain}/auth/realms/SBO/"
  entitycore_url   = "https://${local.primary_domain}/api/entitycore"
  docker_image_url = var.obi_one_docker_image_url

  task_size = var.obi_one_task_size
}

module "obi_generative_gui" {
  source = "./obi_generative_gui"

  aws_region               = local.aws_region
  vpc_id                   = local.vpc_id
  private_alb_listener_arn = local.private_alb_https_listener_arn
  internet_access_route_id = local.route_table_private_subnets_id

  root_path = "/app/obi-generative-gui"

  container_port = 8000
  host_port      = 8000

  keycloak_url     = "https://${local.primary_domain}/auth/realms/SBO/"
  entitycore_url   = "https://${local.primary_domain}/api/entitycore"
  obi_one_url      = "https://${local.primary_domain}/api/obi-one"
  docker_image_url = var.obi_generative_gui_docker_image_url
}

module "kg_inference_api" {
  source = "./kg-inference-api"

  private_alb_https_listener_arn = local.private_alb_https_listener_arn
  route_table_id                 = local.route_table_private_subnets_id
  vpc_cidr_block                 = local.vpc_cidr_block
  vpc_id                         = local.vpc_id

  dockerhub_access_iam_policy_arn = local.dockerhub_bbpbuildbot_policy_arn
  dockerhub_credentials_arn       = local.dockerhub_bbpbuildbot_secret_arn

  aws_region                        = local.aws_region
  account_id                        = local.account_id
  allowed_source_ip_cidr_blocks     = ["0.0.0.0/0"]
  nexus_domain_name                 = module.nexus.nexus_domain_name
  kg_inference_api_docker_image_url = "bluebrain/kg-inference-api:latest"
  kg_inference_api_base_path        = "/api/kg-inference"
  kg_inference_api_log_group_name   = "kg_inference_api"
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
  thumbnail_generation_api_cors_origins     = ["http://localhost:3000", "https://next.staging.openbraininstitute.org"]
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

  virtual_lab_manager_nexus_delta_uri = "https://${module.nexus.nexus_domain_name}/api/nexus/v1"

  virtual_lab_manager_invite_expiration = "7"

  virtual_lab_manager_mail_username = module.ses_user_virtuallab.access_key_id
  virtual_lab_manager_mail_server   = "email-smtp.${local.aws_region}.amazonaws.com"
  virtual_lab_manager_base_path     = var.virtual_lab_manager_base_path
  virtual_lab_manager_mail_password = module.ses_user_virtuallab.ses_smtp_password_v4

  virtual_lab_manager_mail_port = "587"

  virtual_lab_manager_mail_starttls   = "True"
  virtual_lab_manager_use_credentials = "True"
  virtual_lab_manager_cors_origins    = ["http://localhost:3000", "https://next.staging.openbraininstitute.org"]

  virtual_lab_manager_admin_base_path      = "{}/app/virtual-lab/lab/{}/admin?panel=billing"
  virtual_lab_manager_deployment_namespace = "https://${local.primary_domain}"

  virtual_lab_manager_cross_project_resolvers = [
    "public/ephys",
    "public/thalamus",
    "public/ngv",
    "public/multi-vesicular-release",
    "public/hippocampus",
    "public/topological-sampling",
    "bbp/lnmce",
    "public/ngv-anatomy",
    "bbp-external/seu",
    "public/forge",
    "public/sscx",
    "bbp/mouselight",
    "public/morphologies",
    "neurosciencegraph/datamodels",
    "bbp/mmb-point-neuron-framework-model",
    "neurosciencegraph/data",
  ]

  accounting_base_url = "https://${local.primary_domain}${var.accounting_svc_base_path}"
}

module "bbp_workflow_svc" {
  source                         = "./bbp_workflow_svc"
  svc_name                       = "bbp-workflow-svc"
  aws_region                     = local.aws_region
  account_id                     = local.account_id
  vpc_id                         = local.vpc_id
  domain_name                    = local.primary_domain
  route_table_private_subnets_id = local.route_table_private_subnets_id
  nexus_domain_name              = module.nexus.nexus_domain_name
  svc_image                      = "${local.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/bbp-workflow-svc:0.1.dev19"
  kc_scr = (var.is_staging || var.is_production) ? (
    "${local.workflow_service_secrets_arn}:keycloak_client_secret::"
    ) : (
    "arn:aws:secretsmanager:us-east-1:130659266700:secret:bbp-workflow-svc-kc-scr-9c9pEO"
  )
  hpc_provisioner_url = module.hpc.resource_provisioner_api_url
  tags                = { SBO_Billing = "bbp_workflow_svc" }
  count               = (var.is_staging || var.is_production) ? 0 : 1
}

module "dashboards" {
  source = "./dashboards"

  aws_region = local.aws_region

  private_load_balancer_id = local.private_alb_https_listener_arn
  private_load_balancer_target_suffixes = merge({
    "AccountingService"  = module.accounting_svc.private_lb_rule_suffix
    "SonataCellService"  = module.cells_svc.private_lb_rule_suffix
    "KGInference"        = module.kg_inference_api.private_lb_rule_suffix
    "ThumbnailGenerator" = module.thumbnail_generation_api.private_lb_rule_suffix
    "KeyCloak"           = module.cs.private_keycloak_lb_rule_suffix
    "NexusFusion"        = module.nexus.private_fusion_lb_rule_suffix
    "NexusDelta"         = module.nexus.private_delta_lb_rule_suffix
    "CoreWebAppMain"     = module.core_webapp_main.private_lb_rule_suffix
    "VLabManager"        = module.virtual_lab_manager.private_arn_suffix
    "EntityCoreService"  = module.entitycore_svc.private_lb_rule_suffix
  }, var.is_staging ? { "CoreWebAppNext" = module.core_webapp_next[0].private_lb_rule_suffix } : {})
}


module "ses_user_virtuallab" {
  source = "./ses_user"

  user_name = "ses-smtp-user.obp.virtuallabs"
}
