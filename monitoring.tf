# Accounting logs

module "accounting_cloudwatch_error_log_entries_to_sns" {
  source = "./cloudwatch_error_log_entries_to_sns"

  log_group_name    = module.accounting_svc.log_group_name
  unique_short_name = "accounting"
  region            = local.aws_region
  filter_pattern    = "{ $.level = \"ERROR\" }"
  sbo_billing_tag   = "accounting"
}

module "debug_accounting_cloudwatch_error_log_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.accounting_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  unique_short_name         = "accounting_logs"
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

# Accounting DB

module "accounting_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.accounting_svc.rds_db_identifier
  short_name               = "accounting"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 30                      # %
  freeable_memory_low_threshold             = 512 * 1024 * 1024       # 512 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 10
  read_latency_high_threshold               = 0.05             # 50 ms
  write_latency_high_threshold              = 0.02             # 20 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 3   # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 1.0 # 1 active session per vcpu
}

module "debug_accounting_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.accounting_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "accounting_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "accounting_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "accounting_db_metrics"
  sns_topic_arn     = module.accounting_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# Auth Manager DB

module "auth_manager_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.auth_manager.rds_db_identifier
  short_name               = "auth_manager"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 30                      # %
  freeable_memory_low_threshold             = 512 * 1024 * 1024       # 512 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 20
  read_latency_high_threshold               = 0.05             # 50 ms
  write_latency_high_threshold              = 0.02             # 20 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 3   # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 1.0 # 1 active session per vcpu
}

module "debug_auth_manager_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.auth_manager_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "auth_manager_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "auth_manager_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "auth_manager_db_metrics"
  sns_topic_arn     = module.auth_manager_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# EntityCore logs

module "entitycore_cloudwatch_error_log_entries_to_sns" {
  source = "./cloudwatch_error_log_entries_to_sns"

  log_group_name    = module.entitycore_svc.log_group_name
  unique_short_name = "entity_core"
  region            = local.aws_region
  filter_pattern    = "{ $.level = \"ERROR\" || $.level = \"WARNING\" }"
  sbo_billing_tag   = "entitycore"
}

module "debug_entitycore_cloudwatch_error_log_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.entitycore_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  unique_short_name         = "entitycore_logs"
  message_retention_seconds = 172800 # 2 days
}

module "entitycore_error_log_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = "entity_core_logs_errors"

  unique_short_name = "entity_core_logs"
  sns_topic_arn     = module.entitycore_cloudwatch_error_log_entries_to_sns.sns_topic_arn
  python_runtime    = "python3.13"
}

# EntityCore DB

module "entitycore_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.entitycore_svc.rds_db_identifier
  short_name               = "entitycore"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 40                      # %
  freeable_memory_low_threshold             = 50 * 1024 * 1024        # 50 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 40
  read_latency_high_threshold               = 0.05              # 50 ms
  write_latency_high_threshold              = 0.02              # 20 ms
  swap_usage_high_threshold                 = 150 * 1024 * 1024 # 150 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 3   # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 1.0 # 1 active session per vcpu
}

module "debug_entitycore_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.entitycore_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "entitycore_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "entitycore_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "entity_core_db_metrics"
  sns_topic_arn     = module.entitycore_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# Keycloak DB

module "keycloak_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.cs.keycloak_rds_db_identifier
  short_name               = "keycloak"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 20                      # %
  freeable_memory_low_threshold             = 50 * 1024 * 1024        # 50 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 15
  read_latency_high_threshold               = 0.05             # 50 ms
  write_latency_high_threshold              = 0.02             # 20 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 1   # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 0.5 # 1 active session per vcpu
}

module "debug_keycloak_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.keycloak_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "keycloak_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "keycloak_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "keycloak_db_metrics"
  sns_topic_arn     = module.keycloak_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# Launch system DB

module "launch_system_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.launch_system.rds_db_identifier
  short_name               = "launch_system"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 20                      # %
  freeable_memory_low_threshold             = 50 * 1024 * 1024        # 50 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 8
  read_latency_high_threshold               = 0.05             # 50 ms
  write_latency_high_threshold              = 0.02             # 20 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 0.5 # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 0.4 # num active session per vcpu
}

module "debug_launch_system_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.launch_system_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "launch_system_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "launch_system_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "launch_system_db_metrics"
  sns_topic_arn     = module.launch_system_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# ML RDS postgres DB

module "ml_rds_postgres_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.ml.rds_db_identifier
  short_name               = "ml_rds_postgres"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 20                      # %
  freeable_memory_low_threshold             = 50 * 1024 * 1024        # 50 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 15
  read_latency_high_threshold               = 0.03             # 30 ms
  write_latency_high_threshold              = 0.05             # 50 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 0.5 # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 0.4 # num active session per vcpu
}

module "debug_ml_rds_postgres_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.ml_rds_postgres_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "ml_rds_postgres_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "ml_rds_postgres_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "ml_rds_postgres_db_metrics"
  sns_topic_arn     = module.ml_rds_postgres_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# ML Typescript RDS postgres DB

module "ml_rds_ts_postgres_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.ml_typescript.rds_db_identifier
  short_name               = "ml_rds_ts_postgres"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 20                      # %
  freeable_memory_low_threshold             = 50 * 1024 * 1024        # 50 MB
  free_storage_space_low_threshold          = 10 * 1024 * 1024 * 1024 # 10 GB
  database_connections_high_threshold       = 15
  read_latency_high_threshold               = 0.03             # 30 ms
  write_latency_high_threshold              = 0.05             # 50 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 0.5 # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 0.4 # num active session per vcpu
}

module "debug_ml_rds_ts_postgres_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.ml_rds_ts_postgres_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "ml_rds_ts_postgres_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "ml_rds_ts_postgres_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "ml_rds_ts_postgres_db_metrics"
  sns_topic_arn     = module.ml_rds_ts_postgres_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# Virtual Lab Manager DB

module "vlm_db_metrics_alerts" {
  source = "./rds_postgresql_cloudwatch_metric_alarms"

  db_instance_identifier   = module.virtual_lab_manager.rds_db_identifier
  short_name               = "vlm"
  enable_cpu_credit_alarms = true
  enable_db_load_alarms    = true

  cpu_utilization_high_threshold            = 20                     # %
  freeable_memory_low_threshold             = 500 * 1024 * 1024      # 500 MB
  free_storage_space_low_threshold          = 1 * 1024 * 1024 * 1024 # 1 GB
  database_connections_high_threshold       = 15
  read_latency_high_threshold               = 0.03             # 30 ms
  write_latency_high_threshold              = 0.1              # 100 ms
  swap_usage_high_threshold                 = 50 * 1024 * 1024 # 50 MB
  disk_queue_depth_high_threshold           = 1
  cpu_credit_balance_low_threshold          = 200
  cpu_surplus_credit_balance_high_threshold = 5
  db_load_high_threshold                    = 0.5 # average active sessions
  db_load_relative_to_vcpus_high_threshold  = 0.4 # num active session per vcpu
}

module "debug_vlm_db_metrics_alerts_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.vlm_db_metrics_alerts.sns_topic_arn
  unique_short_name         = "vlm_db_metrics"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "vlm_db_metrics_alerts_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "vlm_db_metrics"
  sns_topic_arn     = module.vlm_db_metrics_alerts.sns_topic_arn
  python_runtime    = "python3.13"
}

# Notebook Service

module "notebookservice_cloudwatch_error_log_entries_to_sns" {
  source = "./cloudwatch_error_log_entries_to_sns"

  log_group_name    = module.notebook_service.log_group_name
  unique_short_name = "notebook_service"
  region            = local.aws_region
  sbo_billing_tag   = "notebook_service"
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

module "notebookservice_cloudwatch_metric_alarms" {
  source = "./ecs_container_cloudwatch_metric_alarms"

  ecs_cluster_name                 = module.notebook_service.ecs_cluster_name
  ecs_service_name                 = module.notebook_service.ecs_service_name
  ecs_task_definition_name         = module.notebook_service.ecs_task_definition_name
  ecs_container_names_memory_alarm = module.notebook_service.ecs_container_names

  short_name = "notebook_svc"

  # As there's only a single container: same thresholds for now.
  ecs_service_memory_high_threshold   = 50 # %
  ecs_container_memory_high_threshold = 50 # %
  ecs_task_memory_high_threshold      = 50 # %

  sbo_billing_tag = "notebook_service"
}

module "debug_notebookservice_cloudwatch_metric_alarms" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.notebookservice_cloudwatch_metric_alarms.sns_topic_arn
  unique_short_name         = "nb_alerts"
  message_retention_seconds = 5 * 24 * 60 * 60 # 5 days
}

module "notebookservice_cloudwatch_metric_alarms_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = local.webhook_secret_key_for_metrics_alerts

  unique_short_name = "notebook_service_metric_alerts"
  sns_topic_arn     = module.notebookservice_cloudwatch_metric_alarms.sns_topic_arn
  python_runtime    = "python3.13"
}

# EventBridge - generic AWS errors

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

# SES (Simple Email Service) events

module "aws_ses_events_sns_topic" {
  source = "./aws_ses_events_sns_topic"
}

module "debug_aws_ses_events_sns_topic" {
  source = "./sqs_debug_queue"

  sns_topic_arn             = module.aws_ses_events_sns_topic.sns_topic_arn
  unique_short_name         = "ses_events"
  message_retention_seconds = 172800 # 2 days
}

module "aws_ses_events_sns_entries_to_teams" {
  source = "./sns_entries_to_teams"

  webhook_secret_arn = local.teams_webhook_secrets_arn
  webhook_secret_key = "ses_events"

  unique_short_name = "ses_events"
  sns_topic_arn     = module.aws_ses_events_sns_topic.sns_topic_arn
  python_runtime    = "python3.13"
  handler           = "aws_json_log_sns_to_teams.handle_eventbridge_ses_event"
}

module "eventbridge_archive_for_ses_events" {
  source = "./eventbridge_archive"

  eventbridge_pattern_source      = ["aws.ses"]
  eventbridge_archive_description = "Test archive of SES events"
  eventbridge_archive_name        = "aws_ses_archive"
  eventbridge_retention_days      = 4
}

# Backups

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
