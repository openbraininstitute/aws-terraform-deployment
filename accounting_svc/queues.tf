module "storage_event_queue_set" {
  source = "./queue_set"

  main_queue_name               = "accounting-storage-event-queue.fifo"
  dlq_name                      = "accounting-storage-event-dlq.fifo"
  ecs_accounting_task_role_name = aws_iam_role.ecs_accounting_task_role.name
  read_arn                      = aws_iam_role.ecs_accounting_task_role.arn
}

module "long_job_event_queue_set" {
  source = "./queue_set"

  main_queue_name               = "accounting-long-job-event-queue.fifo"
  dlq_name                      = "accounting-long-job-event-dlq.fifo"
  ecs_accounting_task_role_name = aws_iam_role.ecs_accounting_task_role.name
  read_arn                      = aws_iam_role.ecs_accounting_task_role.arn
}

module "short_job_event_queue_set" {
  source = "./queue_set"

  main_queue_name               = "accounting-short-job-event-queue.fifo"
  dlq_name                      = "accounting-short-job-event-dlq.fifo"
  ecs_accounting_task_role_name = aws_iam_role.ecs_accounting_task_role.name
  read_arn                      = aws_iam_role.ecs_accounting_task_role.arn
}
