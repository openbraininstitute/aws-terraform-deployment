output "iam_policy_writing_accounting_queues" {
  description = "Policy for writing to accounting queues"
  value = {
    arn  = aws_iam_policy.writing_queues.arn
    name = aws_iam_policy.writing_queues.name
  }
}

output "queue_oneshot_event_name" {
  description = "Name of the event queue for oneshot jobs"
  value       = module.oneshot_event_queue_set.main_queue_name
}

output "queue_longrun_event_name" {
  description = "Name of the event queue for longrun jobs"
  value       = module.longrun_event_queue_set.main_queue_name
}

output "queue_storage_event_name" {
  description = "Name of the event queue for storage"
  value       = module.storage_event_queue_set.main_queue_name
}

output "lb_rule_suffix" {
  description = "Accounting Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.accounting.arn_suffix
}
