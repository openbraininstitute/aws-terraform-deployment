module "nexus" {
  source = "./nexus"

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  vpc_id         = data.terraform_remote_state.common.outputs.vpc_id
  vpc_cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block

  dockerhub_access_iam_policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
  dockerhub_credentials_arn       = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn

  domain_zone_id                = data.terraform_remote_state.common.outputs.domain_zone_id
  nat_gateway_id                = data.terraform_remote_state.common.outputs.nat_gateway_id
  private_alb_dns_name          = data.terraform_remote_state.common.outputs.private_alb_dns_name
  private_alb_listener_9999_arn = data.terraform_remote_state.common.outputs.private_alb_listener_9999_arn

  aws_lb_alb_dns_name           = aws_lb.alb.dns_name
  aws_lb_listener_sbo_https_arn = aws_lb_listener.sbo_https.arn

  aws_iam_service_linked_role_depends_on = aws_iam_service_linked_role.os.name
}

moved {
  from = aws_acm_certificate.nexus_app
  to   = module.nexus.aws_acm_certificate.nexus_app
}

moved {
  from = aws_acm_certificate.nexus_fusion
  to   = module.nexus.aws_acm_certificate.nexus_fusion
}

moved {
  from = aws_acm_certificate_validation.nexus_app
  to   = module.nexus.aws_acm_certificate_validation.nexus_app
}

moved {
  from = aws_acm_certificate_validation.nexus_fusion
  to   = module.nexus.aws_acm_certificate_validation.nexus_fusion
}

moved {
  from = aws_cloudwatch_log_group.blazegraph_app
  to   = module.nexus.aws_cloudwatch_log_group.blazegraph_app
}

moved {
  from = aws_cloudwatch_log_group.nexus_app
  to   = module.nexus.aws_cloudwatch_log_group.nexus_app
}

moved {
  from = aws_cloudwatch_log_group.nexus_es
  to   = module.nexus.aws_cloudwatch_log_group.nexus_es
}

moved {
  from = aws_cloudwatch_log_group.nexus_fusion
  to   = module.nexus.aws_cloudwatch_log_group.nexus_fusion
}

moved {
  from = aws_cloudwatch_log_group.nexus_storage
  to   = module.nexus.aws_cloudwatch_log_group.nexus_storage
}

moved {
  from = aws_db_instance.nexusdb
  to   = module.nexus.aws_db_instance.nexusdb
}

moved {
  from = aws_db_subnet_group.nexus_db_subnet_group
  to   = module.nexus.aws_db_subnet_group.nexus_db_subnet_group
}

moved {
  from = aws_ecs_cluster.blazegraph
  to   = module.nexus.aws_ecs_cluster.blazegraph
}

moved {
  from = aws_ecs_cluster.nexus_app
  to   = module.nexus.aws_ecs_cluster.nexus_app
}

moved {
  from = aws_ecs_cluster.nexus_fusion
  to   = module.nexus.aws_ecs_cluster.nexus_fusion
}

moved {
  from = aws_ecs_cluster.nexus_storage
  to   = module.nexus.aws_ecs_cluster.nexus_storage
}

moved {
  from = aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.aws_ecs_service.blazegraph_ecs_service
}

moved {
  from = aws_ecs_service.nexus_app_ecs_service
  to   = module.nexus.aws_ecs_service.nexus_app_ecs_service
}

moved {
  from = aws_ecs_service.nexus_fusion_ecs_service
  to   = module.nexus.aws_ecs_service.nexus_fusion_ecs_service
}

moved {
  from = aws_ecs_service.nexus_storage_ecs_service
  to   = module.nexus.aws_ecs_service.nexus_storage_ecs_service
}

moved {
  from = aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.aws_ecs_task_definition.blazegraph_ecs_definition
}

moved {
  from = aws_ecs_task_definition.nexus_app_ecs_definition
  to   = module.nexus.aws_ecs_task_definition.nexus_app_ecs_definition
}

moved {
  from = aws_ecs_task_definition.nexus_fusion_ecs_definition
  to   = module.nexus.aws_ecs_task_definition.nexus_fusion_ecs_definition
}

moved {
  from = aws_ecs_task_definition.nexus_storage_ecs_definition
  to   = module.nexus.aws_ecs_task_definition.nexus_storage_ecs_definition
}

moved {
  from = aws_efs_backup_policy.nexus_backup_policy
  to   = module.nexus.aws_efs_backup_policy.nexus_backup_policy
}

moved {
  from = aws_efs_backup_policy.policy
  to   = module.nexus.aws_efs_backup_policy.policy
}

moved {
  from = aws_efs_file_system.blazegraph
  to   = module.nexus.aws_efs_file_system.blazegraph
}

moved {
  from = aws_efs_file_system.nexus_app_config
  to   = module.nexus.aws_efs_file_system.nexus_app_config
}

moved {
  from = aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.aws_efs_mount_target.efs_for_blazegraph
}

moved {
  from = aws_efs_mount_target.efs_for_nexus_app
  to   = module.nexus.aws_efs_mount_target.efs_for_nexus_app
}

moved {
  from = aws_iam_policy.sbo_nexus_app_secrets_access
  to   = module.nexus.aws_iam_policy.sbo_nexus_app_secrets_access
}

moved {
  from = aws_iam_role.ecs_blazegraph_task_execution_role
  to   = module.nexus.aws_iam_role.ecs_blazegraph_task_execution_role
}

moved {
  from = aws_iam_role.ecs_nexus_app_task_execution_role
  to   = module.nexus.aws_iam_role.ecs_nexus_app_task_execution_role
}

moved {
  from = aws_iam_role.ecs_nexus_app_task_role
  to   = module.nexus.aws_iam_role.ecs_nexus_app_task_role
}

moved {
  from = aws_iam_role.ecs_nexus_fusion_task_execution_role
  to   = module.nexus.aws_iam_role.ecs_nexus_fusion_task_execution_role
}

moved {
  from = aws_iam_role.ecs_nexus_fusion_task_role
  to   = module.nexus.aws_iam_role.ecs_nexus_fusion_task_role
}

moved {
  from = aws_iam_role.ecs_nexus_storage_task_execution_role
  to   = module.nexus.aws_iam_role.ecs_nexus_storage_task_execution_role
}

moved {
  from = aws_iam_role.ecs_nexus_storage_task_role
  to   = module.nexus.aws_iam_role.ecs_nexus_storage_task_role
}

moved {
  from = aws_iam_role_policy_attachment.ecs_blazegraph_task_execution_role_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_blazegraph_task_execution_role_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_app_secrets_access_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_app_secrets_access_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_app_task_execution_role_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_app_task_execution_role_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_app_task_role_dockerhub_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_app_task_role_dockerhub_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_fusion_task_execution_role_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_fusion_task_execution_role_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_fusion_task_role_dockerhub_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_fusion_task_role_dockerhub_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_storage_task_execution_role_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_storage_task_execution_role_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.ecs_nexus_storage_task_role_dockerhub_policy_attachment
  to   = module.nexus.aws_iam_role_policy_attachment.ecs_nexus_storage_task_role_dockerhub_policy_attachment
}

moved {
  from = aws_lb_listener_certificate.nexus_app
  to   = module.nexus.aws_lb_listener_certificate.nexus_app
}

moved {
  from = aws_lb_listener_certificate.nexus_fusion
  to   = module.nexus.aws_lb_listener_certificate.nexus_fusion
}

moved {
  from = aws_lb_listener_rule.blazegraph_9999
  to   = module.nexus.aws_lb_listener_rule.blazegraph_9999
}

moved {
  from = aws_lb_listener_rule.nexus_app_https
  to   = module.nexus.aws_lb_listener_rule.nexus_app_https
}

moved {
  from = aws_lb_listener_rule.nexus_fusion_https
  to   = module.nexus.aws_lb_listener_rule.nexus_fusion_https
}

moved {
  from = aws_lb_target_group.blazegraph
  to   = module.nexus.aws_lb_target_group.blazegraph
}

moved {
  from = aws_lb_target_group.nexus_app
  to   = module.nexus.aws_lb_target_group.nexus_app
}

moved {
  from = aws_lb_target_group.nexus_fusion
  to   = module.nexus.aws_lb_target_group.nexus_fusion
}

moved {
  from = aws_network_acl.blazegraph
  to   = module.nexus.aws_network_acl.blazegraph
}

moved {
  from = aws_network_acl.nexus_app
  to   = module.nexus.aws_network_acl.nexus_app
}

moved {
  from = aws_network_acl.nexus_db
  to   = module.nexus.aws_network_acl.nexus_db
}

moved {
  from = aws_network_acl.nexus_es
  to   = module.nexus.aws_network_acl.nexus_es
}

moved {
  from = aws_opensearch_domain.nexus_es
  to   = module.nexus.aws_opensearch_domain.nexus_es
}

moved {
  from = aws_route53_record.blazegrap_efs
  to   = module.nexus.aws_route53_record.blazegrap_efs
}

moved {
  from = aws_route53_record.nexus_app
  to   = module.nexus.aws_route53_record.nexus_app
}

moved {
  from = aws_route53_record.nexus_app_efs
  to   = module.nexus.aws_route53_record.nexus_app_efs
}

moved {
  from = aws_route53_record.nexus_app_validation
  to   = module.nexus.aws_route53_record.nexus_app_validation
}

moved {
  from = aws_route53_record.nexus_fusion
  to   = module.nexus.aws_route53_record.nexus_fusion
}

moved {
  from = aws_route53_record.nexus_fusion_validation
  to   = module.nexus.aws_route53_record.nexus_fusion_validation
}

moved {
  from = aws_route53_record.private_blazegraph
  to   = module.nexus.aws_route53_record.private_blazegraph
}

moved {
  from = aws_route_table.blazegraph_app
  to   = module.nexus.aws_route_table.blazegraph_app
}

moved {
  from = aws_route_table.nexus_app
  to   = module.nexus.aws_route_table.nexus_app
}

moved {
  from = aws_route_table.nexus_db
  to   = module.nexus.aws_route_table.nexus_db
}

moved {
  from = aws_route_table.nexus_es
  to   = module.nexus.aws_route_table.nexus_es
}

moved {
  from = aws_route_table_association.blazegraph_app
  to   = module.nexus.aws_route_table_association.blazegraph_app
}

moved {
  from = aws_route_table_association.nexus_app
  to   = module.nexus.aws_route_table_association.nexus_app
}

moved {
  from = aws_route_table_association.nexus_db_a
  to   = module.nexus.aws_route_table_association.nexus_db_a
}

moved {
  from = aws_route_table_association.nexus_db_b
  to   = module.nexus.aws_route_table_association.nexus_db_b
}

moved {
  from = aws_route_table_association.nexus_es_a
  to   = module.nexus.aws_route_table_association.nexus_es_a
}

moved {
  from = aws_route_table_association.nexus_es_b
  to   = module.nexus.aws_route_table_association.nexus_es_b
}

moved {
  from = aws_security_group.blazegraph_ecs_task
  to   = module.nexus.aws_security_group.blazegraph_ecs_task
}

moved {
  from = aws_security_group.blazegraph_efs
  to   = module.nexus.aws_security_group.blazegraph_efs
}

moved {
  from = aws_security_group.nexus_app_ecs_task
  to   = module.nexus.aws_security_group.nexus_app_ecs_task
}

moved {
  from = aws_security_group.nexus_app_efs
  to   = module.nexus.aws_security_group.nexus_app_efs
}

moved {
  from = aws_security_group.nexus_db
  to   = module.nexus.aws_security_group.nexus_db
}

moved {
  from = aws_security_group.nexus_es
  to   = module.nexus.aws_security_group.nexus_es
}

moved {
  from = aws_security_group.nexus_fusion_ecs_task
  to   = module.nexus.aws_security_group.nexus_fusion_ecs_task
}

moved {
  from = aws_security_group.nexus_storage_ecs_task
  to   = module.nexus.aws_security_group.nexus_storage_ecs_task
}

moved {
  from = aws_subnet.blazegraph_app
  to   = module.nexus.aws_subnet.blazegraph_app
}

moved {
  from = aws_subnet.nexus_app
  to   = module.nexus.aws_subnet.nexus_app
}

moved {
  from = aws_subnet.nexus_db_a
  to   = module.nexus.aws_subnet.nexus_db_a
}

moved {
  from = aws_subnet.nexus_db_b
  to   = module.nexus.aws_subnet.nexus_db_b
}

moved {
  from = aws_subnet.nexus_es_a
  to   = module.nexus.aws_subnet.nexus_es_a
}

moved {
  from = aws_subnet.nexus_es_b
  to   = module.nexus.aws_subnet.nexus_es_b
}

moved {
  from = aws_vpc_security_group_egress_rule.blazegraph_ecs_task_tcp_egress
  to   = module.nexus.aws_vpc_security_group_egress_rule.blazegraph_ecs_task_tcp_egress
}

moved {
  from = aws_vpc_security_group_egress_rule.blazegraph_ecs_task_udp_egress
  to   = module.nexus.aws_vpc_security_group_egress_rule.blazegraph_ecs_task_udp_egress
}

moved {
  from = aws_vpc_security_group_egress_rule.nexus_app_allow_outgoing
  to   = module.nexus.aws_vpc_security_group_egress_rule.nexus_app_allow_outgoing
}

moved {
  from = aws_vpc_security_group_egress_rule.nexus_fusion_allow_outgoing
  to   = module.nexus.aws_vpc_security_group_egress_rule.nexus_fusion_allow_outgoing
}

moved {
  from = aws_vpc_security_group_egress_rule.nexus_storage_allow_outgoing
  to   = module.nexus.aws_vpc_security_group_egress_rule.nexus_storage_allow_outgoing
}

moved {
  from = aws_vpc_security_group_ingress_rule.blazegraph_ecs_task_tcp_ingress
  to   = module.nexus.aws_vpc_security_group_ingress_rule.blazegraph_ecs_task_tcp_ingress
}

moved {
  from = aws_vpc_security_group_ingress_rule.blazegraph_ecs_task_udp_ingress
  to   = module.nexus.aws_vpc_security_group_ingress_rule.blazegraph_ecs_task_udp_ingress
}

moved {
  from = aws_vpc_security_group_ingress_rule.nexus_app_allow_port_8080
  to   = module.nexus.aws_vpc_security_group_ingress_rule.nexus_app_allow_port_8080
}

moved {
  from = aws_vpc_security_group_ingress_rule.nexus_fusion_allow_port_8000
  to   = module.nexus.aws_vpc_security_group_ingress_rule.nexus_fusion_allow_port_8000
}

moved {
  from = aws_vpc_security_group_ingress_rule.nexus_storage_allow_port_8080
  to   = module.nexus.aws_vpc_security_group_ingress_rule.nexus_storage_allow_port_8080
}
