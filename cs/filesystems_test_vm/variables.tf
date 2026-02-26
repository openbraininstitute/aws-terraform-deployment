
variable "ec2_type" {
  description = "EC2 instance type for the filesystem tests"
  type        = string
  sensitive   = false
}

variable "jupyterhub_eks_private_a_subnet_id" {
  description = "EKS private subnet a"
  type        = string
  sensitive   = false
}

variable "jupyterhub_eks_private_b_subnet_id" {
  description = "EKS private subnet b"
  type        = string
  sensitive   = false
}

variable "aws_coreservices_ssh_key_id" {
  description = "SSH key for the filesystem tests VM"
  type        = string
  sensitive   = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  sensitive   = false
}

variable "public_data_efs_arn" {
  description = "Public data EFS ARN"
  type        = string
  sensitive   = false
}
