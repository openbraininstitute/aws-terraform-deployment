output "iam_policy_writing_accounting_queues" {
  description = "Policy for writing to accounting queues"
  value = {
    arn  = aws_iam_policy.writing_queues.arn
    name = aws_iam_policy.writing_queues.name
  }
}

output "queue_short_job_event_name" {
  description = "Name of the event queue for short jobs"
  value       = module.short_job_event_queue_set.main_queue_name
}

output "queue_long_job_event_name" {
  description = "Name of the event queue for long jobs"
  value       = module.long_job_event_queue_set.main_queue_name
}

output "queue_storage_event_name" {
  description = "Name of the event queue for storage"
  value       = module.storage_event_queue_set.main_queue_name
}

