moved {
  from = aws_acm_certificate.kg_inference_api_certificate
  to   = module.kg_inference_api.aws_acm_certificate.kg_inference_api_certificate
}

moved {
  from = aws_acm_certificate_validation.kg_inference_api
  to   = module.kg_inference_api.aws_acm_certificate_validation.kg_inference_api
}

moved {
  from = aws_cloudwatch_log_group.kg_inference_api
  to   = module.kg_inference_api.aws_cloudwatch_log_group.kg_inference_api
}

moved {
  from = aws_ecs_cluster.kg_inference_api_cluster
  to   = module.kg_inference_api.aws_ecs_cluster.kg_inference_api_cluster
}

moved {
  from = aws_ecs_service.kg_inference_api_service
  to   = module.kg_inference_api.aws_ecs_service.kg_inference_api_service
}

moved {
  from = aws_ecs_task_definition.kg_inference_api_task_definition
  to   = module.kg_inference_api.aws_ecs_task_definition.kg_inference_api_task_definition
}

moved {
  from = aws_efs_file_system.kg_inference_api_efs_instance
  to   = module.kg_inference_api.aws_efs_file_system.kg_inference_api_efs_instance
}

moved {
  from = aws_efs_mount_target.kg_inference_api_efs_mount_target
  to   = module.kg_inference_api.aws_efs_mount_target.kg_inference_api_efs_mount_target
}

moved {
  from = aws_iam_role.kg_inference_api_ecs_task_execution_role
  to   = module.kg_inference_api.aws_iam_role.kg_inference_api_ecs_task_execution_role
}

moved {
  from = aws_iam_role.kg_inference_api_ecs_task_role
  to   = module.kg_inference_api.aws_iam_role.kg_inference_api_ecs_task_role
}

moved {
  from = aws_iam_role_policy_attachment.kg_inference_api_ecs_task_execution_role_policy_attachment
  to   = module.kg_inference_api.aws_iam_role_policy_attachment.kg_inference_api_ecs_task_execution_role_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.kg_inference_api_ecs_task_role_dockerhub_policy_attachment
  to   = module.kg_inference_api.aws_iam_role_policy_attachment.kg_inference_api_ecs_task_role_dockerhub_policy_attachment
}

moved {
  from = aws_lb_listener_certificate.kg_inference_api
  to   = module.kg_inference_api.aws_lb_listener_certificate.kg_inference_api
}

moved {
  from = aws_lb_listener_rule.kg_inference_api
  to   = module.kg_inference_api.aws_lb_listener_rule.kg_inference_api
}

moved {
  from = aws_lb_target_group.kg_inference_api_tg
  to   = module.kg_inference_api.aws_lb_target_group.kg_inference_api_tg
}

moved {
  from = aws_network_acl.kg_inference_api
  to   = module.kg_inference_api.aws_network_acl.kg_inference_api
}

moved {
  from = aws_route53_record.kg_inference_api
  to   = module.kg_inference_api.aws_route53_record.kg_inference_api
}

moved {
  from = aws_route_table_association.kg_inference_api
  to   = module.kg_inference_api.aws_route_table_association.kg_inference_api
}

moved {
  from = aws_security_group.kg_inference_api_sec_group
  to   = module.kg_inference_api.aws_security_group.kg_inference_api_sec_group
}

moved {
  from = aws_subnet.kg_inference_api
  to   = module.kg_inference_api.aws_subnet.kg_inference_api
}

moved {
  from = aws_vpc_security_group_ingress_rule.kg_inference_api_allow_port_80
  to   = module.kg_inference_api.aws_vpc_security_group_ingress_rule.kg_inference_api_allow_port_80
}

moved {
  from = aws_vpc_security_group_ingress_rule.kg_inference_api_allow_port_8080
  to   = module.kg_inference_api.aws_vpc_security_group_ingress_rule.kg_inference_api_allow_port_8080
}

moved {
  from = aws_vpc_security_group_egress_rule.kg_inference_api_allow_outgoing_tcp
  to   = module.kg_inference_api.aws_vpc_security_group_egress_rule.kg_inference_api_allow_outgoing_tcp
}

moved {
  from = aws_vpc_security_group_egress_rule.kg_inference_api_allow_outgoing_udp
  to   = module.kg_inference_api.aws_vpc_security_group_egress_rule.kg_inference_api_allow_outgoing_udp
}

moved {
  from = aws_iam_role_policy_attachment.ecs_task_execution_role_attachment
  to   = module.thumbnail_generation_api.aws_iam_role_policy_attachment.ecs_task_execution_role_attachment
}

moved {
  from = aws_cloudwatch_log_group.thumbnail_generation_api
  to   = module.thumbnail_generation_api.aws_cloudwatch_log_group.thumbnail_generation_api
}

moved {
  from = aws_ecs_cluster.thumbnail_generation_api_cluster
  to   = module.thumbnail_generation_api.aws_ecs_cluster.thumbnail_generation_api_cluster
}

moved {
  from = aws_ecs_service.thumbnail_generation_api_service
  to   = module.thumbnail_generation_api.aws_ecs_service.thumbnail_generation_api_service
}

moved {
  from = aws_ecs_task_definition.thumbnail_generation_api_task_definition
  to   = module.thumbnail_generation_api.aws_ecs_task_definition.thumbnail_generation_api_task_definition
}

moved {
  from = aws_efs_file_system.thumbnail_generation_api_efs_instance
  to   = module.thumbnail_generation_api.aws_efs_file_system.thumbnail_generation_api_efs_instance
}

moved {
  from = aws_efs_mount_target.thumbnail_generation_api_efs_mount_target
  to   = module.thumbnail_generation_api.aws_efs_mount_target.thumbnail_generation_api_efs_mount_target
}

moved {
  from = aws_iam_policy.thumbnail_generation_api_ecs_task_logs
  to   = module.thumbnail_generation_api.aws_iam_policy.thumbnail_generation_api_ecs_task_logs
}

moved {
  from = aws_iam_role.thumbnail_generation_api_ecs_task_execution_role
  to   = module.thumbnail_generation_api.aws_iam_role.thumbnail_generation_api_ecs_task_execution_role
}

moved {
  from = aws_iam_role.thumbnail_generation_api_ecs_task_role
  to   = module.thumbnail_generation_api.aws_iam_role.thumbnail_generation_api_ecs_task_role
}

moved {
  from = aws_iam_role_policy_attachment.thumbnail_generation_api_ecs_task_execution_role_policy_attachment
  to   = module.thumbnail_generation_api.aws_iam_role_policy_attachment.thumbnail_generation_api_ecs_task_execution_role_policy_attachment
}

moved {
  from = aws_iam_role_policy_attachment.thumbnail_generation_api_ecs_task_role_dockerhub_policy_attachment
  to   = module.thumbnail_generation_api.aws_iam_role_policy_attachment.thumbnail_generation_api_ecs_task_role_dockerhub_policy_attachment
}

moved {
  from = aws_lb_listener_rule.thumbnail_generation_api
  to   = module.thumbnail_generation_api.aws_lb_listener_rule.thumbnail_generation_api
}

moved {
  from = aws_lb_target_group.thumbnail_generation_api_tg
  to   = module.thumbnail_generation_api.aws_lb_target_group.thumbnail_generation_api_tg
}

moved {
  from = aws_network_acl.thumbnail_generation_api
  to   = module.thumbnail_generation_api.aws_network_acl.thumbnail_generation_api
}

moved {
  from = aws_route_table_association.thumbnail_generation_api
  to   = module.thumbnail_generation_api.aws_route_table_association.thumbnail_generation_api
}

moved {
  from = aws_security_group.thumbnail_generation_api_sec_group
  to   = module.thumbnail_generation_api.aws_security_group.thumbnail_generation_api_sec_group
}

moved {
  from = aws_vpc_security_group_ingress_rule.thumbnail_generation_api_allow_port_80
  to   = module.thumbnail_generation_api.aws_vpc_security_group_ingress_rule.thumbnail_generation_api_allow_port_80
}

moved {
  from = aws_vpc_security_group_ingress_rule.thumbnail_generation_api_allow_port_8080
  to   = module.thumbnail_generation_api.aws_vpc_security_group_ingress_rule.thumbnail_generation_api_allow_port_8080
}

moved {
  from = aws_vpc_security_group_egress_rule.thumbnail_generation_api_allow_outgoing_tcp
  to   = module.thumbnail_generation_api.aws_vpc_security_group_egress_rule.thumbnail_generation_api_allow_outgoing_tcp
}

moved {
  from = aws_vpc_security_group_egress_rule.thumbnail_generation_api_allow_outgoing_udp
  to   = module.thumbnail_generation_api.aws_vpc_security_group_egress_rule.thumbnail_generation_api_allow_outgoing_udp
}

moved {
  from = aws_subnet.thumbnail_generation_api
  to   = module.thumbnail_generation_api.aws_subnet.thumbnail_generation_api
}
moved {
  from = aws_route53_record.kg_inference_api_validation["kg-inference-api.shapes-registry.org"]
  to   = module.kg_inference_api.aws_route53_record.kg_inference_api_validation["kg-inference-api.shapes-registry.org"]
}

moved {
  from = aws_network_acl.aws_endpoints
  to   = module.networking.aws_network_acl.aws_endpoints
}

moved {
  from = aws_route_table_association.aws_endpoints
  to   = module.networking.aws_route_table_association.aws_endpoints
}

moved {
  from = aws_security_group.aws_endpoint_secretsmanager
  to   = module.networking.aws_security_group.aws_endpoint_secretsmanager
}

moved {
  from = aws_subnet.aws_endpoints
  to   = module.networking.aws_subnet.aws_endpoints
}

moved {
  from = aws_vpc_endpoint.cloudformation
  to   = module.networking.aws_vpc_endpoint.cloudformation
}

moved {
  from = aws_vpc_endpoint.cloudwatch
  to   = module.networking.aws_vpc_endpoint.cloudwatch
}

moved {
  from = aws_vpc_endpoint.cloudwatch_logs
  to   = module.networking.aws_vpc_endpoint.cloudwatch_logs
}

moved {
  from = aws_vpc_endpoint.dynamodb
  to   = module.networking.aws_vpc_endpoint.dynamodb
}

moved {
  from = aws_vpc_endpoint.ec2
  to   = module.networking.aws_vpc_endpoint.ec2
}

moved {
  from = aws_vpc_endpoint.efs
  to   = module.networking.aws_vpc_endpoint.efs
}

moved {
  from = aws_vpc_endpoint.lambda
  to   = module.networking.aws_vpc_endpoint.lambda
}

moved {
  from = aws_vpc_endpoint.s3
  to   = module.networking.aws_vpc_endpoint.s3
}

moved {
  from = aws_vpc_endpoint.s3express
  to   = module.networking.aws_vpc_endpoint.s3express
}

moved {
  from = aws_vpc_endpoint.secretsmanager
  to   = module.networking.aws_vpc_endpoint.secretsmanager
}

moved {
  from = aws_vpc_endpoint.ssm
  to   = module.networking.aws_vpc_endpoint.ssm
}

moved {
  from = aws_vpc_endpoint.sts
  to   = module.networking.aws_vpc_endpoint.sts
}

moved {
  from = aws_vpc_security_group_egress_rule.aws_endpoint_secretsmanager_outgoing
  to   = module.networking.aws_vpc_security_group_egress_rule.aws_endpoint_secretsmanager_outgoing
}

moved {
  from = aws_vpc_security_group_ingress_rule.aws_endpoint_secretsmanager_incoming
  to   = module.networking.aws_vpc_security_group_ingress_rule.aws_endpoint_secretsmanager_incoming
}
