# ##############################################################################
# A set of example Network ACLs - these were tested and work
# ##############################################################################
#
# resource "aws_network_acl" "slurm_db" {
#   vpc_id     = var.pcluster_vpc_id
#   count      = var.create_slurmdb ? 1 : 0
#   subnet_ids = [local.aws_subnet_slurm_db_a_id, local.aws_subnet_slurm_db_b_id]
#
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = data.aws_vpc.pcluster_vpc.cidr_block
#     from_port  = 3306
#     to_port    = 3306
#   }
#
#   egress {
#     protocol   = "tcp"
#     rule_no    = 110
#     action     = "allow"
#     cidr_block = data.aws_vpc.pcluster_vpc.cidr_block
#     from_port  = 32768
#     to_port    = 61000
#   }
#   tags = {
#     Name = "hpc_slurm_acl"
#   }
# }
#
# resource "aws_network_acl" "public" {
#   vpc_id     = var.pcluster_vpc_id
#   count      = var.create_jumphost ? 1 : 0
#   subnet_ids = [local.aws_subnet_public_id]
#
#   tags = {
#     Name = "public_acl"
#   }
# }
#
# locals {
#   aws_network_acl_public_id  = one(aws_network_acl.public[*].id)
#   aws_network_acl_compute_id = one(aws_network_acl.compute[*].id)
# }
#
# resource "aws_network_acl_rule" "ssh_in" {
#   count          = var.create_jumphost ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   protocol       = "tcp"
#   rule_number    = 100
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 22
#   to_port        = 22
# }
#
# resource "aws_network_acl_rule" "return_traffic_in" {
#   count          = var.create_jumphost ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   protocol       = "tcp"
#   rule_number    = 110
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }
#
# resource "aws_network_acl_rule" "public_local_in" {
#   count          = var.create_jumphost ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   protocol       = -1
#   rule_number    = 130
#   rule_action    = "allow"
#   cidr_block     = data.aws_vpc.pcluster_vpc.cidr_block
#   from_port      = -1
#   to_port        = -1
# }
#
# resource "aws_network_acl_rule" "return_traffic_out" {
#   count          = var.create_jumphost ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   egress         = true
#   protocol       = "tcp"
#   rule_number    = 200
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }
#
# resource "aws_network_acl_rule" "http_out" {
#   count          = var.create_jumphost ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   egress         = true
#   protocol       = "tcp"
#   rule_number    = 210
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 80
#   to_port        = 80
# }
#
# resource "aws_network_acl_rule" "https_out" {
#   count          = var.create_jumphost ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   egress         = true
#   protocol       = "tcp"
#   rule_number    = 220
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 443
#   to_port        = 443
# }
#
# resource "aws_network_acl_rule" "public_local_out" {
#   count          = var.create_jumphost && var.create_compute_instances ? 1 : 0
#   network_acl_id = local.aws_network_acl_public_id
#   egress         = true
#   protocol       = -1
#   rule_number    = 230
#   rule_action    = "allow"
#   cidr_block     = data.aws_vpc.pcluster_vpc.cidr_block
#   from_port      = -1
#   to_port        = -1
# }
#
#
#
# resource "aws_network_acl" "compute" {
#   vpc_id     = var.pcluster_vpc_id
#   count      = var.create_compute_instances ? 1 : 0
#   subnet_ids = local.aws_subnet_compute_ids
#
#   tags = {
#     Name = "compute_acl"
#   }
#
# }
#
# resource "aws_network_acl_rule" "compute_local_in" {
#   count          = var.create_compute_instances ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   rule_number    = 100
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = data.aws_vpc.pcluster_vpc.cidr_block
#   from_port      = 0
#   to_port        = 0
# }
#
# resource "aws_network_acl_rule" "slurm_db_a_in" {
#   count          = var.create_compute_instances && var.create_slurmdb ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   rule_number    = 110
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = local.aws_subnet_slurm_db_a_cidr_block
#   from_port      = 0
#   to_port        = 0
# }
#
# resource "aws_network_acl_rule" "slurm_db_b_in" {
#   count          = var.create_compute_instances && var.create_slurmdb ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   rule_number    = 120
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = local.aws_subnet_slurm_db_b_cidr_block
#   from_port      = 0
#   to_port        = 0
# }
#
# resource "aws_network_acl_rule" "compute_return_traffic" {
#   count          = var.create_compute_instances ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   protocol       = "tcp"
#   rule_number    = 130
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }
#
# resource "aws_network_acl_rule" "compute_local_out" {
#   count          = var.create_compute_instances ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   egress         = true
#   rule_number    = 200
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = data.aws_vpc.pcluster_vpc.cidr_block
#   from_port      = 0
#   to_port        = 0
# }
#
# resource "aws_network_acl_rule" "mysql_a_out" {
#   count          = var.create_compute_instances && var.create_slurmdb ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   egress         = true
#   protocol       = "tcp"
#   rule_number    = 210
#   rule_action    = "allow"
#   cidr_block     = local.aws_subnet_slurm_db_a_cidr_block
#   from_port      = 3306
#   to_port        = 3306
# }
#
# resource "aws_network_acl_rule" "mysql_b_out" {
#   count          = var.create_compute_instances && var.create_slurmdb ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   egress         = true
#   protocol       = "tcp"
#   rule_number    = 220
#   rule_action    = "allow"
#   cidr_block     = local.aws_subnet_slurm_db_b_cidr_block
#   from_port      = 3306
#   to_port        = 3306
# }
#
# # demonstration of how to allow a compute node access to something on the internet
# # work from here if you need more.
# # https is enough for `dnf install` commands
# resource "aws_network_acl_rule" "compute_a_https_out" {
#   count          = var.create_compute_instances && var.compute_nat_access ? 1 : 0
#   network_acl_id = local.aws_network_acl_compute_id
#   egress         = true
#   protocol       = "tcp"
#   rule_number    = 230
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 443
#   to_port        = 443
# }
