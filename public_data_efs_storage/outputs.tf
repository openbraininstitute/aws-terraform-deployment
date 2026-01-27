output "public_launch_data_efs_id" {
  value = aws_efs_file_system.public_launch_data.id
}

output "public_launch_data_efs_arn" {
  value = aws_efs_file_system.public_launch_data.arn
}

output "internal_public_data_access_point_id" {
  value = aws_efs_access_point.internal_public_data_readonly.id
}

output "open_public_data_access_point_id" {
  value = aws_efs_access_point.open_public_data_readonly.id
}

output "internal_public_data_mountpath" {
  value = var.internal_public_data_mountpath
}

output "opendata_mountpath" {
  value = var.opendata_mountpath
}

output "public_launch_efs_securitygroup_arn" {
  value = aws_security_group.public_launch_efs.arn
}