moved {
  from = aws_cloudwatch_log_group.virtual_lab_manager_ecs
  to   = module.virtual_lab_manager.aws_cloudwatch_log_group.virtual_lab_manager_ecs
}
moved {
  from = aws_cloudwatch_log_group.virtual_lab_manager
  to   = module.virtual_lab_manager.aws_cloudwatch_log_group.virtual_lab_manager
}
moved {
  from = aws_db_instance.virtual_lab_manager
  to   = module.virtual_lab_manager.aws_db_instance.virtual_lab_manager
}
moved {
  from = aws_db_subnet_group.virtual_lab_manager_db_subnet_group
  to   = module.virtual_lab_manager.aws_db_subnet_group.virtual_lab_manager_db_subnet_group
}
moved {
  from = aws_ecs_cluster.virtual_lab_manager
  to   = module.virtual_lab_manager.aws_ecs_cluster.virtual_lab_manager
}
moved {
  from = aws_ecs_service.virtual_lab_manager_ecs_service
  to   = module.virtual_lab_manager.aws_ecs_service.virtual_lab_manager_ecs_service
}
moved {
  from = aws_ecs_task_definition.virtual_lab_manager_ecs_definition
  to   = module.virtual_lab_manager.aws_ecs_task_definition.virtual_lab_manager_ecs_definition
}
moved {
  from = aws_iam_policy.ecsTaskLogs_virtuallab
  to   = module.virtual_lab_manager.aws_iam_policy.ecsTaskLogs_virtuallab
}
moved {
  from = aws_iam_policy.virtual_lab_manager_secrets_access
  to   = module.virtual_lab_manager.aws_iam_policy.virtual_lab_manager_secrets_access
}
moved {
  from = aws_iam_role.ecs_virtual_lab_manager_task_execution_role
  to   = module.virtual_lab_manager.aws_iam_role.ecs_virtual_lab_manager_task_execution_role
}
moved {
  from = aws_iam_role.ecs_virtual_lab_manager_task_role
  to   = module.virtual_lab_manager.aws_iam_role.ecs_virtual_lab_manager_task_role
}
moved {
  from = aws_iam_role_policy_attachment.ecs_virtual_lab_manager_attachment_logs
  to   = module.virtual_lab_manager.aws_iam_role_policy_attachment.ecs_virtual_lab_manager_attachment_logs
}
moved {
  from = aws_iam_role_policy_attachment.ecs_virtual_lab_manager_secrets_access_policy_attachment
  to   = module.virtual_lab_manager.aws_iam_role_policy_attachment.ecs_virtual_lab_manager_secrets_access_policy_attachment
}
moved {
  from = aws_iam_role_policy_attachment.ecs_virtual_lab_manager_task_execution_role_policy_attachment
  to   = module.virtual_lab_manager.aws_iam_role_policy_attachment.ecs_virtual_lab_manager_task_execution_role_policy_attachment
}
moved {
  from = aws_iam_role_policy_attachment.ecs_virtual_lab_manager_task_role_dockerhub_policy_attachment
  to   = module.virtual_lab_manager.aws_iam_role_policy_attachment.ecs_virtual_lab_manager_task_role_dockerhub_policy_attachment
}
moved {
  from = aws_lb_listener_rule.virtual_lab_manager
  to   = module.virtual_lab_manager.aws_lb_listener_rule.virtual_lab_manager
}
moved {
  from = aws_lb_target_group.virtual_lab_manager
  to   = module.virtual_lab_manager.aws_lb_target_group.virtual_lab_manager
}
moved {
  from = aws_security_group.virtual_lab_manager_db_sg
  to   = module.virtual_lab_manager.aws_security_group.virtual_lab_manager_db_sg
}
moved {
  from = aws_security_group.virtual_lab_manager_ecs_task
  to   = module.virtual_lab_manager.aws_security_group.virtual_lab_manager_ecs_task
}
moved {
  from = aws_vpc_security_group_egress_rule.virtual_lab_manager_allow_outgoing_tcp
  to   = module.virtual_lab_manager.aws_vpc_security_group_egress_rule.virtual_lab_manager_allow_outgoing_tcp
}
moved {
  from = aws_vpc_security_group_egress_rule.virtual_lab_manager_allow_outgoing_udp
  to   = module.virtual_lab_manager.aws_vpc_security_group_egress_rule.virtual_lab_manager_allow_outgoing_udp
}
moved {
  from = aws_vpc_security_group_ingress_rule.virtual_lab_manager_allow_port_8000
  to   = module.virtual_lab_manager.aws_vpc_security_group_ingress_rule.virtual_lab_manager_allow_port_8000
}
