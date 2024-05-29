moved {
  from = aws_acm_certificate.core_webapp_poc
  to   = module.core_webapp.aws_acm_certificate.core_webapp_poc
}
moved {
  from = aws_acm_certificate_validation.core_webapp_poc
  to   = module.core_webapp.aws_acm_certificate_validation.core_webapp_poc
}
moved {
  from = aws_cloudwatch_log_group.core_webapp
  to   = module.core_webapp.aws_cloudwatch_log_group.core_webapp
}
moved {
  from = aws_cloudwatch_log_group.core_webapp_ecs
  to   = module.core_webapp.aws_cloudwatch_log_group.core_webapp_ecs
}
moved {
  from = aws_ecs_cluster.core_webapp
  to   = module.core_webapp.aws_ecs_cluster.core_webapp
}
moved {
  from = aws_ecs_service.core_webapp_ecs_service[0]
  to   = module.core_webapp.aws_ecs_service.core_webapp_ecs_service[0]
}
moved {
  from = aws_ecs_task_definition.core_webapp_ecs_definition[0]
  to   = module.core_webapp.aws_ecs_task_definition.core_webapp_ecs_definition[0]
}
moved {
  from = aws_iam_policy.sbo_core_webapp_secrets_access
  to   = module.core_webapp.aws_iam_policy.sbo_core_webapp_secrets_access
}
moved {
  from = aws_iam_role.ecs_core_webapp_task_execution_role[0]
  to   = module.core_webapp.aws_iam_role.ecs_core_webapp_task_execution_role[0]
}
moved {
  from = aws_iam_role.ecs_core_webapp_task_role[0]
  to   = module.core_webapp.aws_iam_role.ecs_core_webapp_task_role[0]
}
moved {
  from = aws_iam_role_policy_attachment.ecs_core_webapp_secrets_access_policy_attachment[0]
  to   = module.core_webapp.aws_iam_role_policy_attachment.ecs_core_webapp_secrets_access_policy_attachment[0]
}
moved {
  from = aws_iam_role_policy_attachment.ecs_core_webapp_task_execution_role_policy_attachment[0]
  to   = module.core_webapp.aws_iam_role_policy_attachment.ecs_core_webapp_task_execution_role_policy_attachment[0]
}
moved {
  from = aws_iam_role_policy_attachment.ecs_core_webapp_task_role_dockerhub_policy_attachment[0]
  to   = module.core_webapp.aws_iam_role_policy_attachment.ecs_core_webapp_task_role_dockerhub_policy_attachment[0]
}
moved {
  from = aws_lb_listener_certificate.core_webapp_poc
  to   = module.core_webapp.aws_lb_listener_certificate.core_webapp_poc
}
moved {
  from = aws_lb_listener_rule.core_webapp
  to   = module.core_webapp.aws_lb_listener_rule.core_webapp
}
moved {
  from = aws_lb_listener_rule.core_webapp_poc
  to   = module.core_webapp.aws_lb_listener_rule.core_webapp_poc
}
moved {
  from = aws_lb_listener_rule.core_webapp_redirect
  to   = module.core_webapp.aws_lb_listener_rule.core_webapp_redirect
}
moved {
  from = aws_lb_target_group.core_webapp
  to   = module.core_webapp.aws_lb_target_group.core_webapp
}
moved {
  from = aws_network_acl.core_webapp
  to   = module.core_webapp.aws_network_acl.core_webapp
}
moved {
  from = aws_route53_record.core_webapp_poc
  to   = module.core_webapp.aws_route53_record.core_webapp_poc
}
moved {
  from = aws_route53_record.core_webapp_poc_validation["sbo-core-webapp.shapes-registry.org"]
  to   = module.core_webapp.aws_route53_record.core_webapp_poc_validation["sbo-core-webapp.shapes-registry.org"]
}
moved {
  from = aws_route_table_association.core_webapp
  to   = module.core_webapp.aws_route_table_association.core_webapp
}
moved {
  from = aws_security_group.core_webapp_ecs_task
  to   = module.core_webapp.aws_security_group.core_webapp_ecs_task
}
moved {
  from = aws_subnet.core_webapp
  to   = module.core_webapp.aws_subnet.core_webapp
}
moved {
  from = aws_vpc_security_group_egress_rule.core_webapp_allow_outgoing_tcp
  to   = module.core_webapp.aws_vpc_security_group_egress_rule.core_webapp_allow_outgoing_tcp
}
moved {
  from = aws_vpc_security_group_egress_rule.core_webapp_allow_outgoing_udp
  to   = module.core_webapp.aws_vpc_security_group_egress_rule.core_webapp_allow_outgoing_udp
}
moved {
  from = aws_vpc_security_group_ingress_rule.core_webapp_allow_port_8000
  to   = module.core_webapp.aws_vpc_security_group_ingress_rule.core_webapp_allow_port_8000
}
