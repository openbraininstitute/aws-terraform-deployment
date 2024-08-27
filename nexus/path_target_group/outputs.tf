output "lb_target_group_arn" {
  value = aws_lb_target_group.lb_target_group.arn
}

output "lb_rule_suffix" {
  value = aws_lb_target_group.lb_target_group.arn_suffix
}
