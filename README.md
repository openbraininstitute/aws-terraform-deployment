# deployment

# AWS Deployment

Deployment of the OBI platform in AWS with Terraform.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | ~> 1.75.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.51.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_accounting_cloudwatch_error_log_entries_to_sns"></a> [accounting\_cloudwatch\_error\_log\_entries\_to\_sns](#module\_accounting\_cloudwatch\_error\_log\_entries\_to\_sns) | ./cloudwatch_error_log_entries_to_sns | n/a |
| <a name="module_accounting_db_metrics_alerts"></a> [accounting\_db\_metrics\_alerts](#module\_accounting\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_accounting_db_metrics_alerts_sns_entries_to_teams"></a> [accounting\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_accounting\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_accounting_error_log_sns_entries_to_teams"></a> [accounting\_error\_log\_sns\_entries\_to\_teams](#module\_accounting\_error\_log\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_accounting_svc"></a> [accounting\_svc](#module\_accounting\_svc) | ./accounting_svc | n/a |
| <a name="module_auth_manager"></a> [auth\_manager](#module\_auth\_manager) | ./auth-manager | n/a |
| <a name="module_auth_manager_db_metrics_alerts"></a> [auth\_manager\_db\_metrics\_alerts](#module\_auth\_manager\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_auth_manager_db_metrics_alerts_sns_entries_to_teams"></a> [auth\_manager\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_auth\_manager\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_aws_backups_sns_to_teams"></a> [aws\_backups\_sns\_to\_teams](#module\_aws\_backups\_sns\_to\_teams) | ./sns_lambda_to_teams | n/a |
| <a name="module_aws_errors_sns_topic"></a> [aws\_errors\_sns\_topic](#module\_aws\_errors\_sns\_topic) | ./aws_errors_sns_topic | n/a |
| <a name="module_aws_ses_events_sns_entries_to_teams"></a> [aws\_ses\_events\_sns\_entries\_to\_teams](#module\_aws\_ses\_events\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_aws_ses_events_sns_topic"></a> [aws\_ses\_events\_sns\_topic](#module\_aws\_ses\_events\_sns\_topic) | ./aws_ses_events_sns_topic | n/a |
| <a name="module_backups"></a> [backups](#module\_backups) | ./backups | n/a |
| <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host) | ./bastion_host | n/a |
| <a name="module_cells_svc"></a> [cells\_svc](#module\_cells\_svc) | ./cells_svc | n/a |
| <a name="module_core_webapp_preview"></a> [core\_webapp\_preview](#module\_core\_webapp\_preview) | ./core_webapp_preview | n/a |
| <a name="module_coreservices_key"></a> [coreservices\_key](#module\_coreservices\_key) | ./ssh_key | n/a |
| <a name="module_cs"></a> [cs](#module\_cs) | ./cs | n/a |
| <a name="module_dashboards"></a> [dashboards](#module\_dashboards) | ./dashboards | n/a |
| <a name="module_debug_accounting_cloudwatch_error_log_sns_topic"></a> [debug\_accounting\_cloudwatch\_error\_log\_sns\_topic](#module\_debug\_accounting\_cloudwatch\_error\_log\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_accounting_db_metrics_alerts_sns_topic"></a> [debug\_accounting\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_accounting\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_auth_manager_db_metrics_alerts_sns_topic"></a> [debug\_auth\_manager\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_auth\_manager\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_aws_errors_sns_topic"></a> [debug\_aws\_errors\_sns\_topic](#module\_debug\_aws\_errors\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_aws_ses_events_sns_topic"></a> [debug\_aws\_ses\_events\_sns\_topic](#module\_debug\_aws\_ses\_events\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_entitycore_cloudwatch_error_log_sns_topic"></a> [debug\_entitycore\_cloudwatch\_error\_log\_sns\_topic](#module\_debug\_entitycore\_cloudwatch\_error\_log\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_entitycore_db_metrics_alerts_sns_topic"></a> [debug\_entitycore\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_entitycore\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_keycloak_db_metrics_alerts_sns_topic"></a> [debug\_keycloak\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_keycloak\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_launch_system_db_metrics_alerts_sns_topic"></a> [debug\_launch\_system\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_launch\_system\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_ml_rds_ts_postgres_db_metrics_alerts_sns_topic"></a> [debug\_ml\_rds\_ts\_postgres\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_ml\_rds\_ts\_postgres\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_notebookservice_cloudwatch_error_log_sns_topic"></a> [debug\_notebookservice\_cloudwatch\_error\_log\_sns\_topic](#module\_debug\_notebookservice\_cloudwatch\_error\_log\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_debug_notebookservice_cloudwatch_metric_alarms"></a> [debug\_notebookservice\_cloudwatch\_metric\_alarms](#module\_debug\_notebookservice\_cloudwatch\_metric\_alarms) | ./sqs_debug_queue | n/a |
| <a name="module_debug_vlm_db_metrics_alerts_sns_topic"></a> [debug\_vlm\_db\_metrics\_alerts\_sns\_topic](#module\_debug\_vlm\_db\_metrics\_alerts\_sns\_topic) | ./sqs_debug_queue | n/a |
| <a name="module_development_vm_01"></a> [development\_vm\_01](#module\_development\_vm\_01) | ./development_vm | n/a |
| <a name="module_doi_redirect"></a> [doi\_redirect](#module\_doi\_redirect) | ./redirect_link | n/a |
| <a name="module_entitycore_cloudwatch_error_log_entries_to_sns"></a> [entitycore\_cloudwatch\_error\_log\_entries\_to\_sns](#module\_entitycore\_cloudwatch\_error\_log\_entries\_to\_sns) | ./cloudwatch_error_log_entries_to_sns | n/a |
| <a name="module_entitycore_db_metrics_alerts"></a> [entitycore\_db\_metrics\_alerts](#module\_entitycore\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_entitycore_db_metrics_alerts_sns_entries_to_teams"></a> [entitycore\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_entitycore\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_entitycore_error_log_sns_entries_to_teams"></a> [entitycore\_error\_log\_sns\_entries\_to\_teams](#module\_entitycore\_error\_log\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_entitycore_svc"></a> [entitycore\_svc](#module\_entitycore\_svc) | ./entitycore_svc | n/a |
| <a name="module_eventbridge_archive_for_ses_events"></a> [eventbridge\_archive\_for\_ses\_events](#module\_eventbridge\_archive\_for\_ses\_events) | ./eventbridge_archive | n/a |
| <a name="module_generic_aws_errors_sns_entries_to_teams"></a> [generic\_aws\_errors\_sns\_entries\_to\_teams](#module\_generic\_aws\_errors\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_github_ami_build_role"></a> [github\_ami\_build\_role](#module\_github\_ami\_build\_role) | ./github_ami_build_role | n/a |
| <a name="module_github_keycloak_ecs_redeploy_role"></a> [github\_keycloak\_ecs\_redeploy\_role](#module\_github\_keycloak\_ecs\_redeploy\_role) | ./github_ecs_redeploy_role | n/a |
| <a name="module_github_notebook_service_ecs_redeploy_role"></a> [github\_notebook\_service\_ecs\_redeploy\_role](#module\_github\_notebook\_service\_ecs\_redeploy\_role) | ./github_ecs_redeploy_role | n/a |
| <a name="module_github_oidc_provider"></a> [github\_oidc\_provider](#module\_github\_oidc\_provider) | terraform-module/github-oidc-provider/aws | ~> 2 |
| <a name="module_grading_service"></a> [grading\_service](#module\_grading\_service) | ./grading_service | n/a |
| <a name="module_hpc"></a> [hpc](#module\_hpc) | ./hpc | n/a |
| <a name="module_keycloak_db_metrics_alerts"></a> [keycloak\_db\_metrics\_alerts](#module\_keycloak\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_keycloak_db_metrics_alerts_sns_entries_to_teams"></a> [keycloak\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_keycloak\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_launch_system"></a> [launch\_system](#module\_launch\_system) | ./launch_system | n/a |
| <a name="module_launch_system_db_metrics_alerts"></a> [launch\_system\_db\_metrics\_alerts](#module\_launch\_system\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_launch_system_db_metrics_alerts_sns_entries_to_teams"></a> [launch\_system\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_launch\_system\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_ml_rds_ts_postgres_db_metrics_alerts"></a> [ml\_rds\_ts\_postgres\_db\_metrics\_alerts](#module\_ml\_rds\_ts\_postgres\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_ml_rds_ts_postgres_db_metrics_alerts_sns_entries_to_teams"></a> [ml\_rds\_ts\_postgres\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_ml\_rds\_ts\_postgres\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_ml_typescript"></a> [ml\_typescript](#module\_ml\_typescript) | ./ml | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./networking | n/a |
| <a name="module_nexus"></a> [nexus](#module\_nexus) | ./nexus | n/a |
| <a name="module_notebook_service"></a> [notebook\_service](#module\_notebook\_service) | ./notebook_service | n/a |
| <a name="module_notebookservice_cloudwatch_error_log_entries_to_sns"></a> [notebookservice\_cloudwatch\_error\_log\_entries\_to\_sns](#module\_notebookservice\_cloudwatch\_error\_log\_entries\_to\_sns) | ./cloudwatch_error_log_entries_to_sns | n/a |
| <a name="module_notebookservice_cloudwatch_metric_alarms"></a> [notebookservice\_cloudwatch\_metric\_alarms](#module\_notebookservice\_cloudwatch\_metric\_alarms) | ./ecs_container_cloudwatch_metric_alarms | n/a |
| <a name="module_notebookservice_cloudwatch_metric_alarms_sns_entries_to_teams"></a> [notebookservice\_cloudwatch\_metric\_alarms\_sns\_entries\_to\_teams](#module\_notebookservice\_cloudwatch\_metric\_alarms\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_notebookservice_error_log_sns_entries_to_teams"></a> [notebookservice\_error\_log\_sns\_entries\_to\_teams](#module\_notebookservice\_error\_log\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |
| <a name="module_obi_one_v2"></a> [obi\_one\_v2](#module\_obi\_one\_v2) | ./obi_one_v2 | n/a |
| <a name="module_public_data_efs_storage"></a> [public\_data\_efs\_storage](#module\_public\_data\_efs\_storage) | ./public_data_efs_storage | n/a |
| <a name="module_public_data_sync_opendata"></a> [public\_data\_sync\_opendata](#module\_public\_data\_sync\_opendata) | ./public_data_sync_opendata | n/a |
| <a name="module_ses_user_virtuallab"></a> [ses\_user\_virtuallab](#module\_ses\_user\_virtuallab) | ./ses_user | n/a |
| <a name="module_small_scale_simulator"></a> [small\_scale\_simulator](#module\_small\_scale\_simulator) | ./small_scale_simulator | n/a |
| <a name="module_static-server"></a> [static-server](#module\_static-server) | ./static-server | n/a |
| <a name="module_temporary_nexus_user"></a> [temporary\_nexus\_user](#module\_temporary\_nexus\_user) | ./temporary_user | n/a |
| <a name="module_thumbnail_generation_api"></a> [thumbnail\_generation\_api](#module\_thumbnail\_generation\_api) | ./thumbnail-generation-api | n/a |
| <a name="module_virtual_lab_manager"></a> [virtual\_lab\_manager](#module\_virtual\_lab\_manager) | ./virtual-lab-manager | n/a |
| <a name="module_vlm_db_metrics_alerts"></a> [vlm\_db\_metrics\_alerts](#module\_vlm\_db\_metrics\_alerts) | ./rds_postgresql_cloudwatch_metric_alarms | n/a |
| <a name="module_vlm_db_metrics_alerts_sns_entries_to_teams"></a> [vlm\_db\_metrics\_alerts\_sns\_entries\_to\_teams](#module\_vlm\_db\_metrics\_alerts\_sns\_entries\_to\_teams) | ./sns_entries_to_teams | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_api_gateway_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_iam_role.apigw_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachments_exclusive.apigw_cloudwatch_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachments_exclusive) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_s3_bucket.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_metric.sbo-cell-svc-perf-test-metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_policy.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_versioning.sbo-cell-svc-perf-test-versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.sbo-cell-svc-perf-test-directory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_ami.amazon_linux_2_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.apigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret_version.core_webapp_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [terraform_remote_state.common](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accounting_svc_base_path"></a> [accounting\_svc\_base\_path](#input\_accounting\_svc\_base\_path) | The base path for the accounting service | `string` | `"/api/accounting"` | no |
| <a name="input_accounting_svc_docker_image_url"></a> [accounting\_svc\_docker\_image\_url](#input\_accounting\_svc\_docker\_image\_url) | Docker image for the accounting service | `string` | n/a | yes |
| <a name="input_auth_manager_svc_image_url"></a> [auth\_manager\_svc\_image\_url](#input\_auth\_manager\_svc\_image\_url) | Image URL for auth manager service. | `string` | n/a | yes |
| <a name="input_azure_blobstore_internal_public_data_container_url"></a> [azure\_blobstore\_internal\_public\_data\_container\_url](#input\_azure\_blobstore\_internal\_public\_data\_container\_url) | The URL to the container that will hold internal public data | `string` | n/a | yes |
| <a name="input_azure_blobstore_internal_public_data_sas_token"></a> [azure\_blobstore\_internal\_public\_data\_sas\_token](#input\_azure\_blobstore\_internal\_public\_data\_sas\_token) | SAS token with write access to the internal public data blobstore container | `string` | n/a | yes |
| <a name="input_azure_blobstore_opendata_container_url"></a> [azure\_blobstore\_opendata\_container\_url](#input\_azure\_blobstore\_opendata\_container\_url) | The URL to the container that will hold opendata | `string` | n/a | yes |
| <a name="input_azure_blobstore_opendata_sas_token"></a> [azure\_blobstore\_opendata\_sas\_token](#input\_azure\_blobstore\_opendata\_sas\_token) | SAS token with write access to the opendata blobstore container | `string` | n/a | yes |
| <a name="input_azure_datasync_agent_activation_key_useast1"></a> [azure\_datasync\_agent\_activation\_key\_useast1](#input\_azure\_datasync\_agent\_activation\_key\_useast1) | Activation key for the AWS DataSync agent deployed on Azure for the useast1 AWS region. Short-lived, must be set right before deploy. | `string` | n/a | yes |
| <a name="input_azure_datasync_agent_activation_key_uswest2"></a> [azure\_datasync\_agent\_activation\_key\_uswest2](#input\_azure\_datasync\_agent\_activation\_key\_uswest2) | Activation key for the AWS DataSync agent deployed on Azure for the uswest2 AWS region. Short-lived, must be set right before deploy. | `string` | n/a | yes |
| <a name="input_azure_nfs_internal_public_data_path"></a> [azure\_nfs\_internal\_public\_data\_path](#input\_azure\_nfs\_internal\_public\_data\_path) | NFS export path for internal\_public\_data on azure | `string` | n/a | yes |
| <a name="input_azure_nfs_opendata_path"></a> [azure\_nfs\_opendata\_path](#input\_azure\_nfs\_opendata\_path) | NFS export path for opendata on azure | `string` | n/a | yes |
| <a name="input_azure_nfs_server_hostname"></a> [azure\_nfs\_server\_hostname](#input\_azure\_nfs\_server\_hostname) | Hostname for the NFS share for opendata and internal\_public\_data | `string` | n/a | yes |
| <a name="input_cell_svc_bucket_name"></a> [cell\_svc\_bucket\_name](#input\_cell\_svc\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_cell_svc_docker_image_url"></a> [cell\_svc\_docker\_image\_url](#input\_cell\_svc\_docker\_image\_url) | n/a | `string` | n/a | yes |
| <a name="input_core_web_app_in_azure_cidr_block"></a> [core\_web\_app\_in\_azure\_cidr\_block](#input\_core\_web\_app\_in\_azure\_cidr\_block) | The cidr used by the corewebapp containers which are deployed within azure | `string` | n/a | yes |
| <a name="input_core_web_app_stripe_publishable_key"></a> [core\_web\_app\_stripe\_publishable\_key](#input\_core\_web\_app\_stripe\_publishable\_key) | Stripe publishable key for the core-web-app | `string` | n/a | yes |
| <a name="input_coreservices_public_key"></a> [coreservices\_public\_key](#input\_coreservices\_public\_key) | Public SSH key for the coreservices team | `string` | n/a | yes |
| <a name="input_datasync_target_account"></a> [datasync\_target\_account](#input\_datasync\_target\_account) | Account to which datasync should sync entitycore data | `string` | `""` | no |
| <a name="input_deployment_env"></a> [deployment\_env](#input\_deployment\_env) | The deployment environment, values: 'staging', 'production' | `string` | n/a | yes |
| <a name="input_destination_entitycore_internal_bucket"></a> [destination\_entitycore\_internal\_bucket](#input\_destination\_entitycore\_internal\_bucket) | Destination bucket in {var.datasync\_target\_account} to which entitycore data needs to be synced | `string` | `""` | no |
| <a name="input_entitycore_svc_aws_s3_internal_bucket"></a> [entitycore\_svc\_aws\_s3\_internal\_bucket](#input\_entitycore\_svc\_aws\_s3\_internal\_bucket) | S3 bucket name in which entitycore data lives. | `string` | n/a | yes |
| <a name="input_entitycore_svc_aws_s3_internal_region"></a> [entitycore\_svc\_aws\_s3\_internal\_region](#input\_entitycore\_svc\_aws\_s3\_internal\_region) | S3 region name in which entitycore data lives. | `string` | n/a | yes |
| <a name="input_entitycore_svc_aws_s3_open_bucket"></a> [entitycore\_svc\_aws\_s3\_open\_bucket](#input\_entitycore\_svc\_aws\_s3\_open\_bucket) | S3 bucket name in which open data lives. | `string` | n/a | yes |
| <a name="input_entitycore_svc_aws_s3_open_region"></a> [entitycore\_svc\_aws\_s3\_open\_region](#input\_entitycore\_svc\_aws\_s3\_open\_region) | S3 region name in which open data lives. | `string` | n/a | yes |
| <a name="input_entitycore_svc_image_url"></a> [entitycore\_svc\_image\_url](#input\_entitycore\_svc\_image\_url) | Image URL for entitycore service. | `string` | n/a | yes |
| <a name="input_entitycore_svc_s3_bucket_allowed_origins"></a> [entitycore\_svc\_s3\_bucket\_allowed\_origins](#input\_entitycore\_svc\_s3\_bucket\_allowed\_origins) | Allowed origins for the entitycore service | `list(string)` | n/a | yes |
| <a name="input_grading_service_docker_image_url"></a> [grading\_service\_docker\_image\_url](#input\_grading\_service\_docker\_image\_url) | Docker image URL for the grading service API | `string` | n/a | yes |
| <a name="input_hpc_av_zone_suffixes"></a> [hpc\_av\_zone\_suffixes](#input\_hpc\_av\_zone\_suffixes) | n/a | `list(string)` | n/a | yes |
| <a name="input_hpc_resource_provisioner_containers_bucket"></a> [hpc\_resource\_provisioner\_containers\_bucket](#input\_hpc\_resource\_provisioner\_containers\_bucket) | S3 bucket in which containers can be found. Includes s3:// prefix and sub-path, if any | `string` | n/a | yes |
| <a name="input_hpc_resource_provisioner_data_bucket"></a> [hpc\_resource\_provisioner\_data\_bucket](#input\_hpc\_resource\_provisioner\_data\_bucket) | S3 bucket in which OBI data lives. Includes s3:// prefix and sub-path, if any | `string` | n/a | yes |
| <a name="input_hpc_resource_provisioner_scratch_bucket"></a> [hpc\_resource\_provisioner\_scratch\_bucket](#input\_hpc\_resource\_provisioner\_scratch\_bucket) | S3 bucket in which scratch space lives. Includes s3:// prefix and sub-path, if any | `string` | n/a | yes |
| <a name="input_hpc_resource_provisioner_scratch_bucket_arn"></a> [hpc\_resource\_provisioner\_scratch\_bucket\_arn](#input\_hpc\_resource\_provisioner\_scratch\_bucket\_arn) | ARN for the hpc\_resource\_provisioner\_scratch\_bucket | `string` | n/a | yes |
| <a name="input_infrastructureassets_bucket"></a> [infrastructureassets\_bucket](#input\_infrastructureassets\_bucket) | S3 bucket in which infrastructure assets are stored | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Whether deployment is happening in production or not | `bool` | `true` | no |
| <a name="input_is_staging"></a> [is\_staging](#input\_is\_staging) | Whether deployment is happening in staging | `bool` | `false` | no |
| <a name="input_jupyterhub_ec2_type"></a> [jupyterhub\_ec2\_type](#input\_jupyterhub\_ec2\_type) | JupyterHub service Amazon EC2 Instance type | `string` | `"t3.small"` | no |
| <a name="input_keycloak_client_id"></a> [keycloak\_client\_id](#input\_keycloak\_client\_id) | ID of the Keycloak client | `string` | n/a | yes |
| <a name="input_keycloak_client_uuid"></a> [keycloak\_client\_uuid](#input\_keycloak\_client\_uuid) | UUID of the Keycloak client | `string` | n/a | yes |
| <a name="input_keycloak_sbo_realm_url"></a> [keycloak\_sbo\_realm\_url](#input\_keycloak\_sbo\_realm\_url) | Keycloak realm URL for SBO, for example https://staging.cell-a.openbraininstitute.org/auth/realms/SBO | `string` | n/a | yes |
| <a name="input_keycloak_task_size"></a> [keycloak\_task\_size](#input\_keycloak\_task\_size) | CPU and memory limit for Keycloak's ECS task (number or string format) | <pre>object({<br/>    cpu    = number<br/>    memory = number<br/>  })</pre> | n/a | yes |
| <a name="input_keycloak_url_with_auth"></a> [keycloak\_url\_with\_auth](#input\_keycloak\_url\_with\_auth) | Keycloak URL with auth and slash, for example for example https://staging.cell-a.openbraininstitute.org/auth/ | `string` | n/a | yes |
| <a name="input_launch_system_aca_in_azure_cidr_block"></a> [launch\_system\_aca\_in\_azure\_cidr\_block](#input\_launch\_system\_aca\_in\_azure\_cidr\_block) | The cidr used by the launch-system ACA executors which are deployed within azure | `string` | n/a | yes |
| <a name="input_launch_system_api_task_size"></a> [launch\_system\_api\_task\_size](#input\_launch\_system\_api\_task\_size) | CPU and memory limit for launch-system API task (number or string format) | <pre>object({<br/>    cpu    = any<br/>    memory = any<br/>  })</pre> | n/a | yes |
| <a name="input_launch_system_batch_in_azure_cidr_block"></a> [launch\_system\_batch\_in\_azure\_cidr\_block](#input\_launch\_system\_batch\_in\_azure\_cidr\_block) | The cidr used by the launch-system batch executors which are deployed within azure | `string` | n/a | yes |
| <a name="input_launch_system_executor_task_size"></a> [launch\_system\_executor\_task\_size](#input\_launch\_system\_executor\_task\_size) | CPU and memory limit for launch-system executor tasks (number or string format) | <pre>object({<br/>    cpu    = any<br/>    memory = any<br/>  })</pre> | n/a | yes |
| <a name="input_launch_system_orchestrator_num_workers"></a> [launch\_system\_orchestrator\_num\_workers](#input\_launch\_system\_orchestrator\_num\_workers) | Number of workers processing the queues in the orchestrator task. | `number` | n/a | yes |
| <a name="input_launch_system_orchestrator_task_size"></a> [launch\_system\_orchestrator\_task\_size](#input\_launch\_system\_orchestrator\_task\_size) | CPU and memory limit for launch-system orchestrator task (number or string format) | <pre>object({<br/>    cpu    = any<br/>    memory = any<br/>  })</pre> | n/a | yes |
| <a name="input_ml_neuroagent_typescript_bucket_name"></a> [ml\_neuroagent\_typescript\_bucket\_name](#input\_ml\_neuroagent\_typescript\_bucket\_name) | S3 bucket name for the TypeScript neuroagent stack. Override in staging, production, and sandbox-hpc tfvars. | `string` | `"ml-neuroagent-typescript-unspecified-env"` | no |
| <a name="input_ml_typescript_agent_path_pattern"></a> [ml\_typescript\_agent\_path\_pattern](#input\_ml\_typescript\_agent\_path\_pattern) | Path pattern(s) for the ml\_typescript private ALB listener rule. | `list(string)` | <pre>[<br/>  "/api/agent-ts/*"<br/>]</pre> | no |
| <a name="input_ml_typescript_alb_listener_rule_priority"></a> [ml\_typescript\_alb\_listener\_rule\_priority](#input\_ml\_typescript\_alb\_listener\_rule\_priority) | ALB listener rule priority for ml\_typescript neuroagent (unique on the listener). | `number` | `576` | no |
| <a name="input_ml_typescript_instance_key"></a> [ml\_typescript\_instance\_key](#input\_ml\_typescript\_instance\_key) | instance\_key passed to module ml\_typescript (short suffix, e.g. ts). | `string` | `"ts"` | no |
| <a name="input_ml_typescript_subnet_a_cidr"></a> [ml\_typescript\_subnet\_a\_cidr](#input\_ml\_typescript\_subnet\_a\_cidr) | First private subnet CIDR for module ml\_typescript. Must not overlap module.ml subnets or other subnets in the same VPC.<br/>The same values are often used across staging/production/sandbox-hpc tfvars because each deployment uses a separate VPC (or account); only in-VPC uniqueness matters. | `string` | `"10.0.5.0/24"` | no |
| <a name="input_ml_typescript_subnet_b_cidr"></a> [ml\_typescript\_subnet\_b\_cidr](#input\_ml\_typescript\_subnet\_b\_cidr) | Second private subnet CIDR for module ml\_typescript. Must not overlap module.ml subnets or other subnets in the same VPC.<br/>The same values are often used across staging/production/sandbox-hpc tfvars because each deployment uses a separate VPC (or account); only in-VPC uniqueness matters. | `string` | `"10.0.7.0/24"` | no |
| <a name="input_multiple_vlabs_allowed_user_id"></a> [multiple\_vlabs\_allowed\_user\_id](#input\_multiple\_vlabs\_allowed\_user\_id) | User ID allowed to create multiple virtual labs | `string` | n/a | yes |
| <a name="input_neuroagent_typescript_docker_image_url"></a> [neuroagent\_typescript\_docker\_image\_url](#input\_neuroagent\_typescript\_docker\_image\_url) | ECR image URL for the TypeScript neuroagent stack (module ml\_typescript). Override in staging, production, and sandbox-hpc tfvars. | `string` | `null` | no |
| <a name="input_nexus_obp_bucket_name"></a> [nexus\_obp\_bucket\_name](#input\_nexus\_obp\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_nexus_openscience_bucket_name"></a> [nexus\_openscience\_bucket\_name](#input\_nexus\_openscience\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_nexus_ship_bucket_name"></a> [nexus\_ship\_bucket\_name](#input\_nexus\_ship\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_notebook_service_aws_accounting_enabled"></a> [notebook\_service\_aws\_accounting\_enabled](#input\_notebook\_service\_aws\_accounting\_enabled) | Should accounting be enabled in the notebook service in aws? | `bool` | n/a | yes |
| <a name="input_notebook_service_aws_k8s_thread_enabled"></a> [notebook\_service\_aws\_k8s\_thread\_enabled](#input\_notebook\_service\_aws\_k8s\_thread\_enabled) | Enable kubernetes background thread to check how long notebooks run in aws | `string` | n/a | yes |
| <a name="input_notebook_service_azure_accounting_enabled"></a> [notebook\_service\_azure\_accounting\_enabled](#input\_notebook\_service\_azure\_accounting\_enabled) | Should accounting be enabled in the notebook service in azure? | `bool` | n/a | yes |
| <a name="input_notebook_service_azure_k8s_thread_enabled"></a> [notebook\_service\_azure\_k8s\_thread\_enabled](#input\_notebook\_service\_azure\_k8s\_thread\_enabled) | Enable kubernetes background thread to check how long notebooks run in azure | `string` | n/a | yes |
| <a name="input_notebook_service_azure_storage_account"></a> [notebook\_service\_azure\_storage\_account](#input\_notebook\_service\_azure\_storage\_account) | Azure storage account for the notebook service homedirs for jupyter | `string` | n/a | yes |
| <a name="input_notebook_service_bucket_name"></a> [notebook\_service\_bucket\_name](#input\_notebook\_service\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_notebook_service_docker_image_url"></a> [notebook\_service\_docker\_image\_url](#input\_notebook\_service\_docker\_image\_url) | Docker image for the notebook service | `string` | n/a | yes |
| <a name="input_obi_one_v2_docker_image_url"></a> [obi\_one\_v2\_docker\_image\_url](#input\_obi\_one\_v2\_docker\_image\_url) | Docker image URL for obi-one service. | `string` | n/a | yes |
| <a name="input_obi_one_v2_ec2_instance_type"></a> [obi\_one\_v2\_ec2\_instance\_type](#input\_obi\_one\_v2\_ec2\_instance\_type) | EC2 instance type to run obi-one ECS tasks. | `string` | n/a | yes |
| <a name="input_obi_one_v2_ecs_task_size"></a> [obi\_one\_v2\_ecs\_task\_size](#input\_obi\_one\_v2\_ecs\_task\_size) | CPU and memory limit for obi-one ECS task (number or string format) | <pre>object({<br/>    cpu    = any<br/>    memory = any<br/>    tmpfs  = any # tmpfs size in MiB<br/>  })</pre> | n/a | yes |
| <a name="input_opendata_paths_list"></a> [opendata\_paths\_list](#input\_opendata\_paths\_list) | File in which the paths to sync on opendata are listed, one per line. Should exist in modules/public\_data\_efs | `string` | n/a | yes |
| <a name="input_pcluster_ami_id"></a> [pcluster\_ami\_id](#input\_pcluster\_ami\_id) | n/a | `string` | n/a | yes |
| <a name="input_pcs_ami"></a> [pcs\_ami](#input\_pcs\_ami) | n/a | `string` | n/a | yes |
| <a name="input_resource_provisioner_container_hash"></a> [resource\_provisioner\_container\_hash](#input\_resource\_provisioner\_container\_hash) | n/a | `string` | n/a | yes |
| <a name="input_resource_provisioner_container_uri"></a> [resource\_provisioner\_container\_uri](#input\_resource\_provisioner\_container\_uri) | n/a | `string` | n/a | yes |
| <a name="input_small_scale_simulator_api_docker_image_url"></a> [small\_scale\_simulator\_api\_docker\_image\_url](#input\_small\_scale\_simulator\_api\_docker\_image\_url) | Docker image URL for the small scale simulator API | `string` | n/a | yes |
| <a name="input_small_scale_simulator_api_task_size"></a> [small\_scale\_simulator\_api\_task\_size](#input\_small\_scale\_simulator\_api\_task\_size) | CPU and memory limit for the API ECS task (number or string format) | <pre>object({<br/>    cpu    = any<br/>    memory = any<br/>  })</pre> | n/a | yes |
| <a name="input_small_scale_simulator_batch_workers"></a> [small\_scale\_simulator\_batch\_workers](#input\_small\_scale\_simulator\_batch\_workers) | Map of batch worker configurations. Each key represents an on-demand worker auto-provisioned based on CloudWatch job queue length metrics. | <pre>map(object({<br/>    task_size = object({<br/>      cpu    = any<br/>      memory = any<br/>    })<br/>    num_workers_per_task = number<br/>    queues               = list(string)<br/>    max_worker_tasks     = number<br/>    capacity_provider    = string # Valid values: FARGATE, FARGATE_SPOT<br/>  }))</pre> | `{}` | no |
| <a name="input_small_scale_simulator_daemon_workers"></a> [small\_scale\_simulator\_daemon\_workers](#input\_small\_scale\_simulator\_daemon\_workers) | Map of daemon worker configurations for small scale simulator. Each key represents a worker service name with optional auto-scaling configuration. | <pre>map(object({<br/>    task_size = object({<br/>      cpu    = any<br/>      memory = any<br/>    })<br/>    num_workers_per_task = number<br/>    queues               = list(string)<br/>    num_worker_tasks     = optional(number, 1)<br/>    autoscaler = optional(object({<br/>      enabled              = optional(bool, false)<br/>      max_num_worker_tasks = optional(number, 10)<br/>    }), {})<br/>    capacity_provider_strategy = list(object({<br/>      capacity_provider = string # Valid values: FARGATE, FARGATE_SPOT<br/>      weight            = number<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_small_scale_simulator_worker_docker_image_url"></a> [small\_scale\_simulator\_worker\_docker\_image\_url](#input\_small\_scale\_simulator\_worker\_docker\_image\_url) | Docker image URL for the small scale simulator worker | `string` | n/a | yes |
| <a name="input_source_datasync_role"></a> [source\_datasync\_role](#input\_source\_datasync\_role) | IAM role to allow datasync to write to the S3 bucket. Should exist in the source account data comes from | `string` | `""` | no |
| <a name="input_terraform_remote_state_bucket_name"></a> [terraform\_remote\_state\_bucket\_name](#input\_terraform\_remote\_state\_bucket\_name) | Bucket name storing the deployment-common tfstate | `string` | n/a | yes |
| <a name="input_thumbnail_generation_api_docker_image_url"></a> [thumbnail\_generation\_api\_docker\_image\_url](#input\_thumbnail\_generation\_api\_docker\_image\_url) | Docker image for the thumbnail generation api | `string` | n/a | yes |
| <a name="input_virtual_lab_manager_base_path"></a> [virtual\_lab\_manager\_base\_path](#input\_virtual\_lab\_manager\_base\_path) | The base path for the virtual lab manager | `string` | `"/api/virtual-lab-manager"` | no |
| <a name="input_virtual_lab_manager_docker_image_url"></a> [virtual\_lab\_manager\_docker\_image\_url](#input\_virtual\_lab\_manager\_docker\_image\_url) | Docker image for the virtual lab manager | `string` | n/a | yes |
| <a name="input_virtual_lab_manager_ecs_number_of_containers"></a> [virtual\_lab\_manager\_ecs\_number\_of\_containers](#input\_virtual\_lab\_manager\_ecs\_number\_of\_containers) | Number of containers for the virtual lab manager | `number` | `1` | no |
| <a name="input_virtual_lab_manager_log_group_name"></a> [virtual\_lab\_manager\_log\_group\_name](#input\_virtual\_lab\_manager\_log\_group\_name) | The log name within cloudwatch for the virtual lab manager | `string` | `"virtual_lab_manager"` | no |
| <a name="input_virtual_lab_manager_task_size"></a> [virtual\_lab\_manager\_task\_size](#input\_virtual\_lab\_manager\_task\_size) | CPU and memory limit for ECS task (number or string format) for virtual lab manager | <pre>object({<br/>    cpu    = any<br/>    memory = any<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_github_core_web_app_preview_deploy_role_arn"></a> [github\_core\_web\_app\_preview\_deploy\_role\_arn](#output\_github\_core\_web\_app\_preview\_deploy\_role\_arn) | n/a |
| <a name="output_keycloak_redeploy_role"></a> [keycloak\_redeploy\_role](#output\_keycloak\_redeploy\_role) | n/a |
| <a name="output_notebook_service"></a> [notebook\_service](#output\_notebook\_service) | n/a |
| <a name="output_notebook_service_redeploy_role"></a> [notebook\_service\_redeploy\_role](#output\_notebook\_service\_redeploy\_role) | n/a |
| <a name="output_temporary_nexus_user_credentials"></a> [temporary\_nexus\_user\_credentials](#output\_temporary\_nexus\_user\_credentials) | n/a |
<!-- END_TF_DOCS -->

# Funding and Acknowledgement

The development of this software was supported by funding to the Blue Brain Project, a research center of the École polytechnique fédérale de Lausanne (EPFL), from the Swiss government’s ETH Board of the Swiss Federal Institutes of Technology.

Copyright (c) 2015-2024 Blue Brain Project/EPFL
Copyright (c) 2025 Open Brain Institute
