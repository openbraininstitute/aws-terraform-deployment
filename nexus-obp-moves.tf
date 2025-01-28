moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_cloudwatch_log_group.blazegraph_app
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_cloudwatch_log_group.blazegraph_app
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_ecs_service.blazegraph_ecs_service
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_ecs_task_definition.blazegraph_ecs_definition
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_access_point.blazegraph
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_access_point.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_access_point.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_access_point.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_backup_policy.policy
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_backup_policy.policy
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_backup_policy.policy_config
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_backup_policy.policy_config
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_file_system.blazegraph
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_file_system.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_file_system.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_file_system.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_mount_target.efs_for_blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_mount_target.efs_for_blazegraph_config
  to   = module.nexus.module.blazegraph_obp_bg[0].aws_efs_mount_target.efs_for_blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_cloudwatch_log_group.blazegraph_app
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_cloudwatch_log_group.blazegraph_app
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_ecs_service.blazegraph_ecs_service
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_ecs_task_definition.blazegraph_ecs_definition
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_access_point.blazegraph
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_access_point.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_access_point.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_access_point.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_backup_policy.policy
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_backup_policy.policy
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_backup_policy.policy_config
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_backup_policy.policy_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_file_system.blazegraph
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_file_system.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_file_system.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_file_system.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_mount_target.efs_for_blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_mount_target.efs_for_blazegraph_config
  to   = module.nexus.module.blazegraph_obp_composite[0].aws_efs_mount_target.efs_for_blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_cloudwatch_log_group.blazegraph_app
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_cloudwatch_log_group.blazegraph_app
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_ecs_service.blazegraph_ecs_service
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_ecs_task_definition.blazegraph_ecs_definition
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_access_point.blazegraph
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_access_point.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_access_point.blazegraph_config
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_access_point.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_backup_policy.policy
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_backup_policy.policy
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_backup_policy.policy_config
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_backup_policy.policy_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_file_system.blazegraph
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_file_system.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_file_system.blazegraph_config
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_file_system.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_mount_target.efs_for_blazegraph
}
moved {
  from = module.nexus.module.blazegraph_openscience_bg.aws_efs_mount_target.efs_for_blazegraph_config
  to   = module.nexus.module.blazegraph_openscience_bg[0].aws_efs_mount_target.efs_for_blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_cloudwatch_log_group.blazegraph_app
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_cloudwatch_log_group.blazegraph_app
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_ecs_service.blazegraph_ecs_service
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_ecs_task_definition.blazegraph_ecs_definition
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_access_point.blazegraph
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_access_point.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_access_point.blazegraph_config
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_access_point.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_backup_policy.policy
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_backup_policy.policy
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_backup_policy.policy_config
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_backup_policy.policy_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_file_system.blazegraph
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_file_system.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_file_system.blazegraph_config
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_file_system.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_mount_target.efs_for_blazegraph
}
moved {
  from = module.nexus.module.blazegraph_openscience_composite.aws_efs_mount_target.efs_for_blazegraph_config
  to   = module.nexus.module.blazegraph_openscience_composite[0].aws_efs_mount_target.efs_for_blazegraph_config
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_cloudwatch_log_group.nexus_app
  to   = module.nexus.module.nexus_delta_obp[0].aws_cloudwatch_log_group.nexus_app
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_ecs_service.nexus_app_ecs_service
  to   = module.nexus.module.nexus_delta_obp[0].aws_ecs_service.nexus_app_ecs_service
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_ecs_task_definition.nexus_app_ecs_definition
  to   = module.nexus.module.nexus_delta_obp[0].aws_ecs_task_definition.nexus_app_ecs_definition
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_access_point.delta_config
  to   = module.nexus.module.nexus_delta_obp[0].aws_efs_access_point.delta_config
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_access_point.disk_storage
  to   = module.nexus.module.nexus_delta_obp[0].aws_efs_access_point.disk_storage
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_backup_policy.nexus_backup_policy
  to   = module.nexus.module.nexus_delta_obp[0].aws_efs_backup_policy.nexus_backup_policy
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_file_system.delta
  to   = module.nexus.module.nexus_delta_obp[0].aws_efs_file_system.delta
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_mount_target.efs_for_nexus_app
  to   = module.nexus.module.nexus_delta_obp[0].aws_efs_mount_target.efs_for_nexus_app
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_iam_policy.nexus_delta_s3_bucket_access
  to   = module.nexus.module.nexus_delta_obp[0].aws_iam_policy.nexus_delta_s3_bucket_access
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_iam_role.nexus_delta_ecs_task
  to   = module.nexus.module.nexus_delta_obp[0].aws_iam_role.nexus_delta_ecs_task
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_iam_role_policy_attachment.delta_ecs_task
  to   = module.nexus.module.nexus_delta_obp[0].aws_iam_role_policy_attachment.delta_ecs_task
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_cloudwatch_log_group.nexus_app
  to   = module.nexus.module.nexus_delta_openscience[0].aws_cloudwatch_log_group.nexus_app
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_efs_access_point.delta_config
  to   = module.nexus.module.nexus_delta_openscience[0].aws_efs_access_point.delta_config
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_efs_access_point.disk_storage
  to   = module.nexus.module.nexus_delta_openscience[0].aws_efs_access_point.disk_storage
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_efs_backup_policy.nexus_backup_policy
  to   = module.nexus.module.nexus_delta_openscience[0].aws_efs_backup_policy.nexus_backup_policy
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_efs_file_system.delta
  to   = module.nexus.module.nexus_delta_openscience[0].aws_efs_file_system.delta
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_efs_mount_target.efs_for_nexus_app
  to   = module.nexus.module.nexus_delta_openscience[0].aws_efs_mount_target.efs_for_nexus_app
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_iam_policy.nexus_delta_s3_bucket_access
  to   = module.nexus.module.nexus_delta_openscience[0].aws_iam_policy.nexus_delta_s3_bucket_access
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_iam_role.nexus_delta_ecs_task
  to   = module.nexus.module.nexus_delta_openscience[0].aws_iam_role.nexus_delta_ecs_task
}
moved {
  from = module.nexus.module.nexus_delta_openscience.aws_iam_role_policy_attachment.delta_ecs_task
  to   = module.nexus.module.nexus_delta_openscience[0].aws_iam_role_policy_attachment.delta_ecs_task
}
moved {
  from = module.nexus.module.nexus_fusion_obp.aws_cloudwatch_log_group.nexus_fusion
  to   = module.nexus.module.nexus_fusion_obp[0].aws_cloudwatch_log_group.nexus_fusion
}
moved {
  from = module.nexus.module.nexus_fusion_obp.aws_ecs_service.nexus_fusion_ecs_service
  to   = module.nexus.module.nexus_fusion_obp[0].aws_ecs_service.nexus_fusion_ecs_service
}
moved {
  from = module.nexus.module.nexus_fusion_obp.aws_ecs_task_definition.nexus_fusion_ecs_definition
  to   = module.nexus.module.nexus_fusion_obp[0].aws_ecs_task_definition.nexus_fusion_ecs_definition
}
moved {
  from = module.nexus.module.nexus_fusion_openscience.aws_cloudwatch_log_group.nexus_fusion
  to   = module.nexus.module.nexus_fusion_openscience[0].aws_cloudwatch_log_group.nexus_fusion
}
moved {
  from = module.nexus.module.nexus_fusion_openscience.aws_ecs_service.nexus_fusion_ecs_service
  to   = module.nexus.module.nexus_fusion_openscience[0].aws_ecs_service.nexus_fusion_ecs_service
}
moved {
  from = module.nexus.module.nexus_fusion_openscience.aws_ecs_task_definition.nexus_fusion_ecs_definition
  to   = module.nexus.module.nexus_fusion_openscience[0].aws_ecs_task_definition.nexus_fusion_ecs_definition
}
