output "slurm_db_sg_id" {
  value = local.aws_security_group_slurm_db_sg_id
}

output "compute_efs_sg_id" {
  value = aws_security_group.compute_efs.id
}

output "compute_hpc_sg_id" {
  value = aws_security_group.hpc.id
}

output "jumphost_sg_id" {
  value = local.aws_security_group_jumphost_id
}

output "vpc_peering_security_group_id" {
  value = aws_security_group.peering.id
}
