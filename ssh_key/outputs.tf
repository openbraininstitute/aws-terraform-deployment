output "key_pair_id" {
  description = "The id of the aws_key_pair resource"
  value       = aws_key_pair.key.id
  sensitive   = false
}
output "key_pair_arn" {
  description = "The arn of the aws_key_pair resource"
  value       = aws_key_pair.key.arn
  sensitive   = false
}
