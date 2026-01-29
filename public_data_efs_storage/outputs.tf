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

output "mount_target_ip_address1_as_cidr" {
  value       = "${aws_efs_mount_target.public_launch_data[0].ip_address}/32"
  description = "ip address 1 of the mount target, which can be used in network acl rules"
}

output "mount_target_ip_address2_as_cidr" {
  value       = "${aws_efs_mount_target.public_launch_data[1].ip_address}/32"
  description = "ip address 1 of the mount target, which can be used in network acl rules"
}
