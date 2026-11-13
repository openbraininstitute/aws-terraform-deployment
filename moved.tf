# thumbnail_generation_api: count added (staging and production only); keep the running service
moved {
  from = module.thumbnail_generation_api
  to   = module.thumbnail_generation_api[0]
}

# Remove count from launch_system module
moved {
  from = module.launch_system[0]
  to   = module.launch_system
}

# Add count to research_agent module (prod-ai#142) - without this, the
# resources are planned as destroy+recreate at the new [0]-indexed
# address, which makes their attributes unknown-until-apply and breaks
# ml/agent.tf's own count expression that reads them.
moved {
  from = module.research_agent
  to   = module.research_agent[0]
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

# ECS Managed Instances GPU executor: preserve state across Terraform address renames
# (ASG-based executor_gpu_ec2_* → executor_gpu_*). AWS-facing name changes such as
# capacity provider name or security group name_prefix cannot use moved blocks and
# may still force replacement where the remote API does not support rename.
moved {
  from = module.launch_system.data.aws_iam_policy_document.executor_gpu_ec2_instance_role_assume
  to   = module.launch_system.data.aws_iam_policy_document.executor_gpu_instance_role_assume
}

moved {
  from = module.launch_system.aws_iam_role.executor_gpu_ec2_instance
  to   = module.launch_system.aws_iam_role.executor_gpu_instance
}

moved {
  from = module.launch_system.aws_iam_role_policy_attachment.executor_gpu_ec2_instance_ecs
  to   = module.launch_system.aws_iam_role_policy_attachment.executor_gpu_instance_ecs
}

moved {
  from = module.launch_system.aws_iam_role_policy_attachment.executor_gpu_instance_ecs
  to   = module.launch_system.aws_iam_role_policy_attachment.executor_gpu_instance_managed_instances
}

moved {
  from = module.launch_system.aws_iam_role_policy_attachment.executor_gpu_ec2_instance_ssm
  to   = module.launch_system.aws_iam_role_policy_attachment.executor_gpu_instance_ssm
}

moved {
  from = module.launch_system.aws_iam_instance_profile.executor_gpu_ec2_instance
  to   = module.launch_system.aws_iam_instance_profile.executor_gpu_instance
}

moved {
  from = module.launch_system.aws_security_group.executor_gpu_ec2_instance
  to   = module.launch_system.aws_security_group.executor_gpu_instance
}

moved {
  from = module.launch_system.aws_vpc_security_group_egress_rule.executor_gpu_ec2_instance_allow_outgoing
  to   = module.launch_system.aws_vpc_security_group_egress_rule.executor_gpu_instance_allow_outgoing
}
