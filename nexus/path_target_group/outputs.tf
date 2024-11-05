output "private_lb_target_group_arn" {
  value = aws_lb_target_group.private_lb_target_group.arn
}

output "private_lb_rule_suffix" {
  value = aws_lb_target_group.private_lb_target_group.arn_suffix
}
