output "lb_target_group_arn" {
  value = aws_lb_target_group.nexus_app.arn
}

output "hostname" {
  value = var.nexus_delta_hostname
}