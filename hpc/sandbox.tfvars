aws_region                 = "us-east-1"
obp_vpc_id                 = "vpc-06465039e2fbae370"
sbo_billing                = "hpc"
slurm_mysql_admin_username = "slurm_admin"
slurm_mysql_admin_password = "arn:aws:secretsmanager:us-east-1:130659266700:secret:slurm-accounting-db-TgsUIE"
create_compute_instances   = false
num_compute_instances      = 1
compute_instance_type      = "m7g.medium"
create_slurmdb             = false
create_jumphost            = false
compute_nat_access         = false
compute_subnet_count       = 15
av_zone_suffixes           = ["a", "b", "c", "d"]
peering_route_tables       = ["rtb-0d570d1a815939248"]
existing_route_targets     = ["172.31.0.0/16"]