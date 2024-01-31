output "efs_delta_dns_name" {
  value = aws_efs_mount_target.efs_for_nexus_app.dns_name
}