output "efs_delta_dns_name" {
  # value = aws_efs_mount_target.efs_for_nexus_app.dns_name
  value = module.storage.aws_efs_mount_target_efs_for_nexus_app_dns_name
}

output "nexus_delta_bucket_arn" {
  value = var.s3_bucket_arn
}

output "service_name" {
  value = length(module.ecs) > 0 ? module.ecs[0].aws_ecs_service_nexus_app_ecs_service_name : null
}
