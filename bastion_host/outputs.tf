
output "ssm_document_names" {
  description = "Names of all created SSM documents for user mapping"
  value = {
    for user in local.all_users :
    user.username => aws_ssm_document.user_specific_mapping[user.username].name
  }
}

output "ssm_document_arns" {
  description = "ARNs of all created SSM documents for user mapping"
  value = {
    for user in local.all_users :
    user.username => aws_ssm_document.user_specific_mapping[user.username].arn
  }
}

output "session_log_bucket" {
  value = aws_s3_bucket.session_logs.id
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.session_logs.name
}

output "bastion_instance_id" {
  description = "EC2 instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_instance_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}
