output "lb_target_group_arn" {
  value = aws_lb_target_group.nexus_fusion.arn
}

output "hostname" {
  value = var.nexus_fusion_hostname
}
