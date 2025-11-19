output "public_launch_data_efs_id" {
  value = aws_efs_file_system.public_launch_data.id
}

output "internal_public_data_access_point_id" {
  value = aws_efs_access_point.internal_public_data_readonly.id
}

output "open_public_data_access_point_id" {
  value = aws_efs_access_point.open_public_data_readonly.id
}
