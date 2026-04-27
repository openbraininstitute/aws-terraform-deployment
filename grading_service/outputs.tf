output "private_lb_rule_suffix" {
  description = "Grading service load balancer rule suffix"
  value       = aws_lb_target_group.main.arn_suffix
}
