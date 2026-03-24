output "vm_instance_id" {
  description = "EC2 instance ID of the VM"
  value       = aws_instance.instance.id
}

output "vm_instance_private_ip" {
  description = "Private IP address of the VM"
  value       = aws_instance.instance.private_ip
}
