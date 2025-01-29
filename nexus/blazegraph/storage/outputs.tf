output "aws_efs_file_system_blazegraph_id" {
  value = aws_efs_file_system.blazegraph.id
}

output "aws_efs_file_system_blazegraph_config_id" {
  value = aws_efs_file_system.blazegraph_config.id
}

output "aws_efs_access_point_blazegraph_id" {
  value = aws_efs_access_point.blazegraph.id
}

output "aws_efs_access_point_blazegraph_config_id" {
  value = aws_efs_access_point.blazegraph_config.id
}

output "aws_efs_mount_target_efs_for_blazegraph_dns_name" {
  value = aws_efs_mount_target.efs_for_blazegraph.dns_name
}
