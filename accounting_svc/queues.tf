module "storage_event_queue_set" {
  source = "./queue_set"

  main_queue_name = "accounting-storage-event-queue.fifo"
  dlq_name        = "accounting-storage-event-dlq.fifo"
  read_arn        = aws_iam_role.ecs_accounting_task_role.arn
}

module "longrun_event_queue_set" {
  source = "./queue_set"

  main_queue_name = "accounting-longrun-event-queue.fifo"
  dlq_name        = "accounting-longrun-event-dlq.fifo"
  read_arn        = aws_iam_role.ecs_accounting_task_role.arn
}

module "oneshot_event_queue_set" {
  source = "./queue_set"

  main_queue_name = "accounting-oneshot-event-queue.fifo"
  dlq_name        = "accounting-oneshot-event-dlq.fifo"
  read_arn        = aws_iam_role.ecs_accounting_task_role.arn
}
