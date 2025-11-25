output "jupyterhub_homedirs_efs_file_system_id" {
  value       = aws_efs_file_system.users_homedirs.id
  description = "ID of the EFS file system that is used to store user home directories on."
}

output "jupyterhub_homedirs_efs_security_group_id" {
  description = "ID of the security group of the EFS filesystem with the jupyterhub home dirs"
  value       = aws_security_group.efs_homedirs_sg.id
}