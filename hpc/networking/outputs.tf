output "slurm_db_subnets_ids" {
  value = [local.aws_subnet_slurm_db_a_id, local.aws_subnet_slurm_db_b_id]
}

output "slurm_db_a_subnet_id" {
  value = local.aws_subnet_slurm_db_a_id
}

output "compute_subnet_ids" {
  value = local.aws_subnet_compute_ids
}

output "compute_subnet_public_id" {
  value = local.aws_subnet_public_id
}

output "compute_subnet_efs_ids" {
  value = local.aws_subnet_compute_efs_ids
}
