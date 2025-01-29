output "aws_efs_file_system_delta_id" {
  value = aws_efs_file_system.delta.id
}

output "aws_efs_access_point_delta_config_id" {
  value = aws_efs_access_point.delta_config.id
}

output "aws_efs_access_point_disk_storage_id" {
  value = aws_efs_access_point.disk_storage.id
}
