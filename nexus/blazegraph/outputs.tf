output "efs_blazegraph_dns_name" {
  value = aws_efs_mount_target.efs_for_blazegraph.dns_name
}