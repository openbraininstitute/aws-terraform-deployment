output "efs_mount_target_dns_name" {
  value = aws_efs_file_system.compute_efs.dns_name
}
