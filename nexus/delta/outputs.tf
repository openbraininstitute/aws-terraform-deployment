output "efs_delta_dns_name" {
  value = aws_efs_mount_target.efs_for_nexus_app.dns_name
}

output "nexus_delta_bucket_arn" {
  value = var.s3_bucket_arn
}

output "service_name" {
  value = aws_ecs_service.nexus_app_ecs_service.name
}
