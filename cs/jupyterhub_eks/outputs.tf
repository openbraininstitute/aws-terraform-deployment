output "jupyterhub_homedirs_efs_file_system_id" {
  value       = aws_efs_file_system.users_homedirs.id
  description = "ID of the EFS file system that is used to store user home directories on."
}

output "jupyterhub_homedirs_efs_security_group_id" {
  description = "ID of the security group of the EFS filesystem with the jupyterhub home dirs"
  value       = aws_security_group.efs_homedirs_sg.id
}

output "private_subnet_a_id" {
  value = aws_subnet.jupyterhub_eks_private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.jupyterhub_eks_private_b.id
}

output "jupyterhub_eks_public_a_cidr" {
  value       = var.jupyterhub_eks_public_a_cidr
  description = "CIDR of JupyterHub EKS public subnet A"
}

output "jupyterhub_eks_public_b_cidr" {
  value       = var.jupyterhub_eks_public_b_cidr
  description = "CIDR of JupyterHub EKS public subnet B"
}

output "jupyterhub_eks_private_a_cidr" {
  value       = var.jupyterhub_eks_private_a_cidr
  description = "CIDR of JupyterHub EKS private subnet A"
}

output "jupyterhub_eks_private_b_cidr" {
  value       = var.jupyterhub_eks_private_b_cidr
  description = "CIDR of JupyterHub EKS private subnet B"
}
