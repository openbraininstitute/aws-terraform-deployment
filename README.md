# deployment

# AWS Deployment

Deployment of the OBI platform in AWS with Terraform.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version            |
| ------------------------------------------------------------------------ | ------------------ |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.2.0           |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | ~> 5.55, != 5.71.0 |
| <a name="requirement_ec"></a> [ec](#requirement_ec)                      | ~> 0.9.0           |

## Providers

| Name                                                               | Version |
| ------------------------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)                   | 5.84.0  |
| <a name="provider_terraform"></a> [terraform](#provider_terraform) | n/a     |

## Modules

| Name                                                                                                        | Source                     | Version |
| ----------------------------------------------------------------------------------------------------------- | -------------------------- | ------- |
| <a name="module_accounting_svc"></a> [accounting_svc](#module_accounting_svc)                               | ./accounting_svc           | n/a     |
| <a name="module_bbp_workflow_svc"></a> [bbp_workflow_svc](#module_bbp_workflow_svc)                         | ./bbp_workflow_svc         | n/a     |
| <a name="module_billing_cost_management"></a> [billing_cost_management](#module_billing_cost_management)    | ./billing_cost_management  | n/a     |
| <a name="module_cells_svc"></a> [cells_svc](#module_cells_svc)                                              | ./cells_svc                | n/a     |
| <a name="module_core_webapp"></a> [core_webapp](#module_core_webapp)                                        | ./core_webapp              | n/a     |
| <a name="module_coreservices_key"></a> [coreservices_key](#module_coreservices_key)                         | ./ssh_key                  | n/a     |
| <a name="module_cs"></a> [cs](#module_cs)                                                                   | ./cs                       | n/a     |
| <a name="module_dashboards"></a> [dashboards](#module_dashboards)                                           | ./dashboards               | n/a     |
| <a name="module_hpc"></a> [hpc](#module_hpc)                                                                | ./hpc                      | n/a     |
| <a name="module_kg_inference_api"></a> [kg_inference_api](#module_kg_inference_api)                         | ./kg-inference-api         | n/a     |
| <a name="module_ml"></a> [ml](#module_ml)                                                                   | ./ml                       | n/a     |
| <a name="module_networking"></a> [networking](#module_networking)                                           | ./networking               | n/a     |
| <a name="module_nexus"></a> [nexus](#module_nexus)                                                          | ./nexus                    | n/a     |
| <a name="module_nse"></a> [nse](#module_nse)                                                                | ./nse                      | n/a     |
| <a name="module_static-server"></a> [static-server](#module_static-server)                                  | ./static-server            | n/a     |
| <a name="module_thumbnail_generation_api"></a> [thumbnail_generation_api](#module_thumbnail_generation_api) | ./thumbnail-generation-api | n/a     |
| <a name="module_virtual_lab_manager"></a> [virtual_lab_manager](#module_virtual_lab_manager)                | ./virtual-lab-manager      | n/a     |
| <a name="module_viz"></a> [viz](#module_viz)                                                                | ./viz                      | n/a     |

## Resources

| Name                                                                                                                                                                                                       | Type        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_api_gateway_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account)                                                                            | resource    |
| [aws_iam_group.obp_nse_team](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group)                                                                                        | resource    |
| [aws_iam_group_membership.obp_nse_team](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership)                                                                  | resource    |
| [aws_iam_group_policy_attachment.nse-policy-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment)                                               | resource    |
| [aws_iam_policy.cell_svc_bucket_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                                                       | resource    |
| [aws_iam_role.apigw_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                                      | resource    |
| [aws_iam_role_policy_attachments_exclusive.apigw_cloudwatch_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachments_exclusive)          | resource    |
| [aws_iam_user.cell_svc_bucket_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user)                                                                                  | resource    |
| [aws_instance.ssh_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                                                                                           | resource    |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl)                                                                                          | resource    |
| [aws_route53_record.ssh_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                                                               | resource    |
| [aws_s3_bucket.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                                              | resource    |
| [aws_s3_bucket_lifecycle_configuration.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)                              | resource    |
| [aws_s3_bucket_metric.sbo-cell-svc-perf-test-metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric)                                                        | resource    |
| [aws_s3_bucket_public_access_block.sbo-cell-svc-perf-test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)                                      | resource    |
| [aws_s3_bucket_versioning.sbo-cell-svc-perf-test-versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)                                             | resource    |
| [aws_s3_object.sbo-cell-svc-perf-test-directory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)                                                                    | resource    |
| [aws_security_group.ssh_bastion_hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                                         | resource    |
| [aws_ssoadmin_permission_set.readonly_with_additional_billing_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                                 | resource    |
| [aws_ssoadmin_permission_set.readonly_with_additional_dashboard_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                               | resource    |
| [aws_ssoadmin_permission_set.readonly_with_additional_ecs_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                                     | resource    |
| [aws_ssoadmin_permission_set.readonly_with_additional_hpc_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                                     | resource    |
| [aws_ssoadmin_permission_set.readonly_with_additional_s3_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                                      | resource    |
| [aws_ssoadmin_permission_set.readonly_with_additional_waframework_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                             | resource    |
| [aws_ssoadmin_permission_set_inline_policy.readonly_with_additional_billing_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy)     | resource    |
| [aws_ssoadmin_permission_set_inline_policy.readonly_with_additional_dashboard_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy)   | resource    |
| [aws_ssoadmin_permission_set_inline_policy.readonly_with_additional_ecs_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy)         | resource    |
| [aws_ssoadmin_permission_set_inline_policy.readonly_with_additional_hpc_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy)         | resource    |
| [aws_ssoadmin_permission_set_inline_policy.readonly_with_additional_s3_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy)          | resource    |
| [aws_ssoadmin_permission_set_inline_policy.readonly_with_additional_waframework_rights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy) | resource    |
| [aws_vpc_security_group_egress_rule.ssh_bastion_hosts_allow_everything_outgoing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule)               | resource    |
| [aws_vpc_security_group_ingress_rule.ssh_bastion_hosts_allow_http_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule)                   | resource    |
| [aws_vpc_security_group_ingress_rule.ssh_bastion_hosts_allow_https_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule)                  | resource    |
| [aws_vpc_security_group_ingress_rule.ssh_bastion_hosts_allow_ssh_external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule)                    | resource    |
| [aws_ami.almalinux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)                                                                                                    | data source |
| [aws_ami.amazon_linux_2_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)                                                                                           | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                                                              | data source |
| [aws_iam_policy_document.apigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                                                                        | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                                                                | data source |
| [aws_ssoadmin_instances.ssoadmin_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances)                                                             | data source |
| [terraform_remote_state.common](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state)                                                                         | data source |

## Inputs

| Name                                                                                                                                                                  | Description                                                                                                    | Type     | Default                                  | Required |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------- | :------: |
| <a name="input_cell_svc_bucket_name"></a> [cell_svc_bucket_name](#input_cell_svc_bucket_name)                                                                         | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_core_web_app_docker_image_url"></a> [core_web_app_docker_image_url](#input_core_web_app_docker_image_url)                                              | docker image for the core-web-app                                                                              | `string` | n/a                                      |   yes    |
| <a name="input_create_ssh_bastion_vm_on_public_a_network"></a> [create_ssh_bastion_vm_on_public_a_network](#input_create_ssh_bastion_vm_on_public_a_network)          | Create SSH bastion VM on public network in availability zone A: needed for access to HPC resources for example | `bool`   | `true`                                   |    no    |
| <a name="input_ec_apikey"></a> [ec_apikey](#input_ec_apikey)                                                                                                          | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_is_production"></a> [is_production](#input_is_production)                                                                                              | Whether deployment is happening in production or not                                                           | `bool`   | `true`                                   |    no    |
| <a name="input_ml_paper_bucket_name"></a> [ml_paper_bucket_name](#input_ml_paper_bucket_name)                                                                         | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_nexus_az_letter_id"></a> [nexus_az_letter_id](#input_nexus_az_letter_id)                                                                               | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_nexus_domain_name"></a> [nexus_domain_name](#input_nexus_domain_name)                                                                                  | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_nexus_obp_bucket_name"></a> [nexus_obp_bucket_name](#input_nexus_obp_bucket_name)                                                                      | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_nexus_openscience_bucket_name"></a> [nexus_openscience_bucket_name](#input_nexus_openscience_bucket_name)                                              | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_nexus_ship_bucket_name"></a> [nexus_ship_bucket_name](#input_nexus_ship_bucket_name)                                                                   | n/a                                                                                                            | `string` | n/a                                      |   yes    |
| <a name="input_nise_dockerhub_password"></a> [nise_dockerhub_password](#input_nise_dockerhub_password)                                                                | Password for the NISE dockerhub access. Set via TF_VAR_nise_dockerhub_password variable.                       | `string` | n/a                                      |   yes    |
| <a name="input_terraform_remote_state_bucket_name"></a> [terraform_remote_state_bucket_name](#input_terraform_remote_state_bucket_name)                               | Bucket name storing the deployment-common tfstate                                                              | `string` | n/a                                      |   yes    |
| <a name="input_virtual_lab_manager_base_path"></a> [virtual_lab_manager_base_path](#input_virtual_lab_manager_base_path)                                              | The base path for the virtual lab manager                                                                      | `string` | `"/api/virtual-lab-manager"`             |    no    |
| <a name="input_virtual_lab_manager_docker_image_url"></a> [virtual_lab_manager_docker_image_url](#input_virtual_lab_manager_docker_image_url)                         | docker image for the virtual lab manager                                                                       | `string` | `"bluebrain/obp-virtual-lab-api:latest"` |    no    |
| <a name="input_virtual_lab_manager_ecs_number_of_containers"></a> [virtual_lab_manager_ecs_number_of_containers](#input_virtual_lab_manager_ecs_number_of_containers) | Number of containers for the virtual lab manager                                                               | `number` | `1`                                      |    no    |
| <a name="input_virtual_lab_manager_log_group_name"></a> [virtual_lab_manager_log_group_name](#input_virtual_lab_manager_log_group_name)                               | The log name within cloudwatch for the virtual lab manager                                                     | `string` | `"virtual_lab_manager"`                  |    no    |

## Outputs

| Name                                                                                                                                   | Description |
| -------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| <a name="output_admin_vm_on_public_a_dns_cname"></a> [admin_vm_on_public_a_dns_cname](#output_admin_vm_on_public_a_dns_cname)          | n/a         |
| <a name="output_admin_vm_on_public_a_network_ip"></a> [admin_vm_on_public_a_network_ip](#output_admin_vm_on_public_a_network_ip)       | n/a         |
| <a name="output_admin_vm_on_public_a_network_name"></a> [admin_vm_on_public_a_network_name](#output_admin_vm_on_public_a_network_name) | n/a         |
| <a name="output_admin_vm_on_public_b_network_ip"></a> [admin_vm_on_public_b_network_ip](#output_admin_vm_on_public_b_network_ip)       | n/a         |
| <a name="output_admin_vm_on_public_b_network_name"></a> [admin_vm_on_public_b_network_name](#output_admin_vm_on_public_b_network_name) | n/a         |

<!-- END_TF_DOCS -->

# Funding and Acknowledgement

The development of this software was supported by funding to the Blue Brain Project, a research center of the École polytechnique fédérale de Lausanne (EPFL), from the Swiss government’s ETH Board of the Swiss Federal Institutes of Technology.

Copyright (c) 2015-2024 Blue Brain Project/EPFL
Copyright (c) 2025 Open Brain Institute
