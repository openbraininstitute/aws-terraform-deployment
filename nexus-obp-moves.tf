moved {
  from = module.nexus.aws_ecs_cluster.nexus
  to   = module.nexus.module.ecs_cluster.aws_ecs_cluster.nexus[0]
}
moved {
  from = module.nexus.aws_service_discovery_http_namespace.nexus
  to   = module.nexus.module.ecs_cluster.aws_service_discovery_http_namespace.nexus[0]
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.module.blazegraph_obp_bg.module.ecs[0].aws_ecs_service.blazegraph_ecs_service
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.module.blazegraph_obp_bg.module.ecs[0].aws_ecs_task_definition.blazegraph_ecs_definition
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_access_point.blazegraph
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_access_point.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_access_point.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_access_point.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_backup_policy.policy
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_backup_policy.policy
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_backup_policy.policy_config
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_backup_policy.policy_config
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_file_system.blazegraph
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_file_system.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_file_system.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_file_system.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_mount_target.efs_for_blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_bg.aws_efs_mount_target.efs_for_blazegraph_config
  to   = module.nexus.module.blazegraph_obp_bg.module.storage.aws_efs_mount_target.efs_for_blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_ecs_service.blazegraph_ecs_service
  to   = module.nexus.module.blazegraph_obp_composite.module.ecs[0].aws_ecs_service.blazegraph_ecs_service
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_ecs_task_definition.blazegraph_ecs_definition
  to   = module.nexus.module.blazegraph_obp_composite.module.ecs[0].aws_ecs_task_definition.blazegraph_ecs_definition
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_access_point.blazegraph
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_access_point.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_access_point.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_access_point.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_backup_policy.policy
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_backup_policy.policy
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_backup_policy.policy_config
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_backup_policy.policy_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_file_system.blazegraph
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_file_system.blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_file_system.blazegraph_config
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_file_system.blazegraph_config
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_mount_target.efs_for_blazegraph
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_mount_target.efs_for_blazegraph
}
moved {
  from = module.nexus.module.blazegraph_obp_composite.aws_efs_mount_target.efs_for_blazegraph_config
  to   = module.nexus.module.blazegraph_obp_composite.module.storage.aws_efs_mount_target.efs_for_blazegraph_config
}
moved {
  from = module.nexus.module.nexus_delta_obp.module.ecs.aws_cloudwatch_log_group.nexus_app
  to   = module.nexus.module.nexus_delta_obp.aws_cloudwatch_log_group.nexus_app
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_ecs_service.nexus_app_ecs_service
  to   = module.nexus.module.nexus_delta_obp.module.ecs.aws_ecs_service.nexus_app_ecs_service
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_ecs_task_definition.nexus_app_ecs_definition
  to   = module.nexus.module.nexus_delta_obp.module.ecs.aws_ecs_task_definition.nexus_app_ecs_definition
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_access_point.delta_config
  to   = module.nexus.module.nexus_delta_obp.module.storage.aws_efs_access_point.delta_config
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_access_point.disk_storage
  to   = module.nexus.module.nexus_delta_obp.module.storage.aws_efs_access_point.disk_storage
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_backup_policy.nexus_backup_policy
  to   = module.nexus.module.nexus_delta_obp.module.storage.aws_efs_backup_policy.nexus_backup_policy
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_file_system.delta
  to   = module.nexus.module.nexus_delta_obp.module.storage.aws_efs_file_system.delta
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_efs_mount_target.efs_for_nexus_app
  to   = module.nexus.module.nexus_delta_obp.module.storage.aws_efs_mount_target.efs_for_nexus_app
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_iam_policy.nexus_delta_s3_bucket_access
  to   = module.nexus.module.nexus_delta_obp.module.ecs.aws_iam_policy.nexus_delta_s3_bucket_access
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_iam_role.nexus_delta_ecs_task
  to   = module.nexus.module.nexus_delta_obp.module.ecs.aws_iam_role.nexus_delta_ecs_task
}
moved {
  from = module.nexus.module.nexus_delta_obp.aws_iam_role_policy_attachment.delta_ecs_task
  to   = module.nexus.module.nexus_delta_obp.module.ecs.aws_iam_role_policy_attachment.delta_ecs_task
}

moved {
  from = module.nexus.module.nexus_delta_obp.module.ecs.aws_ecs_service.nexus_app_ecs_service
  to   = module.nexus.module.nexus_delta_obp.module.ecs[0].aws_ecs_service.nexus_app_ecs_service
}

moved {
  from = module.nexus.module.nexus_delta_obp.module.ecs.aws_ecs_task_definition.nexus_app_ecs_definition
  to   = module.nexus.module.nexus_delta_obp.module.ecs[0].aws_ecs_task_definition.nexus_app_ecs_definition
}
moved {
  from = module.nexus.module.nexus_fusion_obp.aws_ecs_service.nexus_fusion_ecs_service
  to   = module.nexus.module.nexus_fusion_obp.module.ecs[0].aws_ecs_service.nexus_fusion_ecs_service
}
moved {
  from = module.nexus.module.nexus_fusion_obp.aws_ecs_task_definition.nexus_fusion_ecs_definition
  to   = module.nexus.module.nexus_fusion_obp.module.ecs[0].aws_ecs_task_definition.nexus_fusion_ecs_definition
}
moved {
  from = module.nexus.module.nexus_delta_obp.module.ecs.aws_iam_policy.nexus_delta_s3_bucket_access
  to   = module.nexus.module.nexus_delta_obp.module.ecs[0].aws_iam_policy.nexus_delta_s3_bucket_access
}
moved {
  from = module.nexus.module.nexus_delta_obp.module.ecs.aws_iam_role.nexus_delta_ecs_task
  to   = module.nexus.module.nexus_delta_obp.module.ecs[0].aws_iam_role.nexus_delta_ecs_task
}
moved {
  from = module.nexus.module.nexus_delta_obp.module.ecs.aws_iam_role_policy_attachment.delta_ecs_task
  to   = module.nexus.module.nexus_delta_obp.module.ecs[0].aws_iam_role_policy_attachment.delta_ecs_task
}
