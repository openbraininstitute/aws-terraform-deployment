locals {
  aws_subnet_slurm_db_a_id   = one(aws_subnet.slurm_db_a[*].id)
  aws_subnet_slurm_db_b_id   = one(aws_subnet.slurm_db_b[*].id)
  aws_route_table_slurmdb_id = one(aws_route_table.slurmdb[*].id)
}

# Subnet for RDS MySQL DB for SLURM on AZ a
resource "aws_subnet" "slurm_db_a" {
  vpc_id            = var.pcluster_vpc_id
  count             = var.create_slurmdb ? 1 : 0
  availability_zone = "${var.aws_region}a"
  cidr_block        = "172.32.2.0/24"
  tags = {
    Name = "slurm_db_a"
  }
}

# Subnet for RDS MySQL DB for SLURM on AZ b
resource "aws_subnet" "slurm_db_b" {
  vpc_id            = var.pcluster_vpc_id
  count             = var.create_slurmdb ? 1 : 0
  availability_zone = "${var.aws_region}b"
  cidr_block        = "172.32.3.0/24"
  tags = {
    Name = "slurm_db_b"
  }
}

resource "aws_route_table" "slurmdb" {
  vpc_id = var.pcluster_vpc_id
  count  = var.create_slurmdb ? 1 : 0
  tags = {
    Name = "slurm_db_route"
  }
}

# Link route table to slurm db networks
resource "aws_route_table_association" "slurm_db_a" {
  count          = var.create_slurmdb ? 1 : 0
  subnet_id      = local.aws_subnet_slurm_db_a_id
  route_table_id = local.aws_route_table_slurmdb_id
}

resource "aws_route_table_association" "slurm_db_b" {
  count          = var.create_slurmdb ? 1 : 0
  subnet_id      = local.aws_subnet_slurm_db_b_id
  route_table_id = local.aws_route_table_slurmdb_id
}
