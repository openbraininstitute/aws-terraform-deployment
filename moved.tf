# Remove count from launch_system module
moved {
  from = module.launch_system[0]
  to   = module.launch_system
}

# Merge launch_system_network into launch_system
moved {
  from = module.launch_system_network.aws_subnet.trusted_a
  to   = module.launch_system.aws_subnet.trusted_a
}

moved {
  from = module.launch_system_network.aws_subnet.trusted_b
  to   = module.launch_system.aws_subnet.trusted_b
}

moved {
  from = module.launch_system_network.aws_subnet.untrusted_a
  to   = module.launch_system.aws_subnet.untrusted_a
}

moved {
  from = module.launch_system_network.aws_subnet.untrusted_b
  to   = module.launch_system.aws_subnet.untrusted_b
}

moved {
  from = module.launch_system_network.aws_route_table_association.trusted_a_internet_access
  to   = module.launch_system.aws_route_table_association.trusted_a_internet_access
}

moved {
  from = module.launch_system_network.aws_route_table_association.trusted_b_internet_access
  to   = module.launch_system.aws_route_table_association.trusted_b_internet_access
}

moved {
  from = module.launch_system_network.aws_route_table_association.untrusted_a_internet_access
  to   = module.launch_system.aws_route_table_association.untrusted_a_internet_access
}

moved {
  from = module.launch_system_network.aws_route_table_association.untrusted_b_internet_access
  to   = module.launch_system.aws_route_table_association.untrusted_b_internet_access
}

moved {
  from = module.launch_system.aws_iam_policy.secrets_access
  to   = module.launch_system.aws_iam_policy.full_secrets_access
}

moved {
  from = module.launch_system.aws_iam_role.executor_execution
  to   = module.launch_system.aws_iam_role.inait_executor_execution
}

moved {
  from = module.launch_system.aws_iam_role_policy_attachment.executor_execution
  to   = module.launch_system.aws_iam_role_policy_attachment.inait_executor_execution
}

moved {
  from = module.launch_system.aws_iam_role_policy_attachment.executor_logs_access
  to   = module.launch_system.aws_iam_role_policy_attachment.inait_executor_logs_access
}
