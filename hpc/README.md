Variables to set
================

  * `aws_region`: fairly self-explanatory. The module will append a/b/c/d here and there for availability zone division
  * `vpc_id`: the ID of an existing VPC that will be peered with the pcluster VPC
  * `sbo_billing`: the value for the SBO_Billing tag
  * `slurm_mysql_admin_username`: the username to set for the slurmdb
  * `slurm_mysql_admin_password`: the reference to the secrets secret that holds the password for the slurmd admin account
  * `create_compute_instances`: do we want to create the compute instances and assorted objects or not?
  * `num_compute_instances`: how many compute instances to set up. Can be set to 0 if you just want the other objects (e.g. subnets)
  * `compute_instance_type`: which type to use for the compute instances
  * `create_slurmdb`: create the slurmdb and assorted objects or not?
  * `compute_nat_access`: do the compute nodes need NAT access? Only set up if `create_compute_instances` is `true`
  * `compute_subnet_count`: how many compute subnets to create.
  * `av_zone_suffixes`: which availability zones (a, b, c, ...) to create the compute subnets in
  * `peering_route_tables`: which route tables need to get an extra route to the peering VPC
  * `existing_route_targets`: which CIDRs should be reachable from the pcluster VPC

Tags
====

For the HPC Resource Provisioner to be able to identify certain resources it's allowed to use, we add the `HPC_Goal:compute_cluster` tag to them. This is the case for:

  * the compute subnets
  * the EFS
  * the security group
  * the SSH keypair
