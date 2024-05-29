output "efs_delta_dns_name" {
  value = aws_efs_mount_target.efs_for_nexus_app.dns_name
}

output "nexus_delta_bucket_arn" {
  value = aws_s3_bucket.nexus_delta.arn
}

output "nexus_bucket_arn" {
  value = aws_s3_bucket.nexus.arn
}