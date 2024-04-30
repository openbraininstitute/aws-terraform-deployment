# ##############################################################################
# Prevent the different compute subnets from talking to each other.
# ##############################################################################

resource "aws_network_acl" "compute" {
  vpc_id     = var.pcluster_vpc_id
  count      = var.compute_subnet_count
  subnet_ids = [aws_subnet.compute[count.index].id]
}

# About this monstrosity
#
# count:
# ------
# We want an aws_network_acl for every compute network (var.compute_subnet_count)
# Every aws_network_acl needs a rule per compute subnet _except_ itself (var.compute_subnet_count - 1)
#
# network_acl_id:
# ---------------
# modulo is a nice way to keep iterating through the different aws_network_acl objects
#
# cidr_block:
# -----------
# When writing a few variations of var.compute_subnet_count out in three columns (count.index, network_acl_id, aws_subnet.compute[index]), there's a pattern:
# the network index gets a +1 for the first line of the first iteration, for the first two lines of the second iteration, etc
# rephrased: the last +1 happens every time count.index / network_acl_id is exactly var.compute_subnet_count + 1 (as well as for the first entry - but don't divide by 0!)
#
# since terraform logical operators don't short-circuit, doing something like `count.index == 0 || (count.index / network_acl_id)` is impossible (don't divide by 0!)
# so we complicate things...
# `count.index % var.compute_subnet_count` is the compute subnet index
#
# count.index / var.compute_subnet_count tells us which iteration we're in (0-based) and so which compute subnet we want to block
# the rest of it is to see whether we should increment that by an additional +1:
#
# if count.index <= var.compute_subnet_count AND compute_subnet_index == 0
# OR
# if count.index / (compute_subnet_index or 1 if it's 0) >= var.compute_subnet_count + 1
# THEN
# add one to the compute_subnet_index we want to block

resource "aws_network_acl_rule" "deny_other_compute_subnets" {
  count          = var.compute_subnet_count * (var.compute_subnet_count - 1)
  network_acl_id = aws_network_acl.compute[count.index % var.compute_subnet_count].id
  protocol       = -1
  rule_number    = 1000 + count.index
  rule_action    = "deny"
  cidr_block = aws_subnet.compute[
    floor(count.index / var.compute_subnet_count + (
      (
        ((count.index <= (var.compute_subnet_count) && (count.index % var.compute_subnet_count) == 0) ||
          ((count.index / ((count.index % var.compute_subnet_count) == 0 ? 1 : count.index % var.compute_subnet_count)) >= (var.compute_subnet_count + 1))
        )
      ) ? 1 : 0)
    )
  ].cidr_block
  from_port = -1
  to_port   = -1
}

# now do it again, but for egress
resource "aws_network_acl_rule" "deny_other_compute_subnets_egress" {
  count          = var.compute_subnet_count * (var.compute_subnet_count - 1)
  network_acl_id = aws_network_acl.compute[count.index % var.compute_subnet_count].id
  egress         = true
  protocol       = -1
  rule_number    = 2000 + count.index
  rule_action    = "deny"
  cidr_block = aws_subnet.compute[
    floor(count.index / var.compute_subnet_count + (
      (
        ((count.index <= (var.compute_subnet_count) && (count.index % var.compute_subnet_count) == 0) ||
          ((count.index / ((count.index % var.compute_subnet_count) == 0 ? 1 : count.index % var.compute_subnet_count)) >= (var.compute_subnet_count + 1))
        )
      ) ? 1 : 0)
    )
  ].cidr_block
  from_port = -1
  to_port   = -1
}

# Refine as needed, for now we just want to block traffic between compute subnets
resource "aws_network_acl_rule" "allow_other_traffic_from_pcluster_vpc" {
  count          = var.compute_subnet_count
  network_acl_id = aws_network_acl.compute[count.index].id
  protocol       = -1
  rule_number    = 4000 + count.index
  rule_action    = "allow"
  cidr_block     = data.aws_vpc.pcluster_vpc.cidr_block
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "allow_other_traffic_to_pcluster_vpc" {
  count          = var.compute_subnet_count
  network_acl_id = aws_network_acl.compute[count.index].id
  egress         = true
  protocol       = -1
  rule_number    = 4100 + count.index
  rule_action    = "allow"
  cidr_block     = data.aws_vpc.pcluster_vpc.cidr_block
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "allow_other_traffic_from_obp_vpc" {
  count          = var.compute_subnet_count
  network_acl_id = aws_network_acl.compute[count.index].id
  protocol       = -1
  rule_number    = 4200 + count.index
  rule_action    = "allow"
  cidr_block     = data.aws_vpc.obp_vpc.cidr_block
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "allow_other_traffic_to_obp_vpc" {
  count          = var.compute_subnet_count
  network_acl_id = aws_network_acl.compute[count.index].id
  egress         = true
  protocol       = -1
  rule_number    = 4300 + count.index
  rule_action    = "allow"
  cidr_block     = data.aws_vpc.obp_vpc.cidr_block
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "allow_return_traffic_in" {
  count          = var.compute_subnet_count
  network_acl_id = aws_network_acl.compute[count.index].id
  protocol       = "tcp"
  rule_number    = 4400 + count.index
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# for S3 traffic
resource "aws_network_acl_rule" "allow_https_traffic_out" {
  count          = var.compute_subnet_count
  network_acl_id = aws_network_acl.compute[count.index].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 4500 + count.index
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

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
