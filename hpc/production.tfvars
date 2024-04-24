# example only - the real variables are defined in ../main.tf

aws_region                 = "us-east-1"
obp_vpc_id                 = "vpc-0f4c0dae68dde7f59"
sbo_billing                = "hpc"
slurm_mysql_admin_username = "slurm_admin"
slurm_mysql_admin_password = "arn:aws:secretsmanager:us-east-1:671250183987:secret:hpc_slurm_db_password-6LNuBy"
create_compute_instances   = false
num_compute_instances      = 0
compute_instance_type      = "m7g.medium"
# TODO-SLURMDB: re-enable once redeploying everything
create_slurmdb         = false
create_jumphost        = false
compute_nat_access     = false
compute_subnet_count   = 15
av_zone_suffixes       = ["a", "b", "c", "d"]
peering_route_tables   = []
existing_route_targets = []
