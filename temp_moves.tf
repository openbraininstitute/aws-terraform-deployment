moved {
  from = module.public_data_efs[0].aws_datasync_location_efs.internal_destination
  to   = module.public_data_sync_opendata[0].aws_datasync_location_efs.internal_destination
}

moved {
  from = module.public_data_efs[0].aws_efs_access_point.internal_public_data_readonly
  to   = module.public_data_efs_storage.aws_efs_access_point.internal_public_data_readonly
}

moved {
  from = module.public_data_efs[0].aws_efs_access_point.open_public_data_readonly
  to   = module.public_data_efs_storage.aws_efs_access_point.open_public_data_readonly
}

moved {
  from = module.public_data_efs[0].aws_efs_file_system.public_launch_data
  to   = module.public_data_efs_storage.aws_efs_file_system.public_launch_data
}

moved {
  from = module.public_data_efs[0].aws_datasync_location_efs.opendata_destination
  to   = module.public_data_sync_opendata[0].aws_datasync_location_efs.opendata_destination
}

moved {
  from = module.public_data_efs[0].aws_datasync_location_s3.internal_source
  to   = module.public_data_sync_opendata[0].aws_datasync_location_s3.internal_source
}

moved {
  from = module.public_data_efs[0].aws_datasync_location_s3.opendata_source
  to   = module.public_data_sync_opendata[0].aws_datasync_location_s3.opendata_source
}

moved {
  from = module.public_data_efs[0].aws_datasync_task.internal_s3_to_efs
  to   = module.public_data_sync_opendata[0].aws_datasync_task.internal_s3_to_efs
}

moved {
  from = module.public_data_efs[0].aws_datasync_task.opendata_s3_to_efs
  to   = module.public_data_sync_opendata[0].aws_datasync_task.opendata_s3_to_efs
}

moved {
  from = module.public_data_efs[0].aws_security_group.public_launch_efs
  to   = module.public_data_efs_storage.aws_security_group.public_launch_efs
}

moved {
  from = module.public_data_efs[0].aws_vpc_security_group_egress_rule.datasync_nfs_access
  to   = module.public_data_efs_storage.aws_vpc_security_group_egress_rule.datasync_nfs_access
}

moved {
  from = module.public_data_efs[0].aws_vpc_security_group_ingress_rule.public_launch_nfs_access
  to   = module.public_data_efs_storage.aws_vpc_security_group_ingress_rule.public_launch_nfs_access
}

moved {
  from = module.public_data_efs[0].aws_efs_mount_target.public_launch_data[0]
  to   = module.public_data_efs_storage.aws_efs_mount_target.public_launch_data[0]
}

moved {
  from = module.public_data_efs[0].aws_efs_mount_target.public_launch_data[1]
  to   = module.public_data_efs_storage.aws_efs_mount_target.public_launch_data[1]
}

moved {
  from = module.public_data_efs[0].aws_iam_role.datasync_s3_role
  to   = module.public_data_sync_opendata[0].aws_iam_role.datasync_s3_role
}

moved {
  from = module.public_data_efs[0].aws_iam_role_policy.datasync_s3_policy
  to   = module.public_data_sync_opendata[0].aws_iam_role_policy.datasync_s3_policy
}
