output "main_queue_name" {
  value = aws_sqs_queue.main_queue.name
}

output "main_queue_arn" {
  value = aws_sqs_queue.main_queue.arn
}
