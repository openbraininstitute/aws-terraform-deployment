# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "pcluster_vpc" {
  cidr_block           = "172.32.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "parallel-clusters"
  }
}

resource "aws_vpc_peering_connection" "test_to_pcluster" {
  peer_vpc_id = aws_vpc.pcluster_vpc.id
  vpc_id      = var.obp_vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "VPC peer connection between OBP VPC and pcluster VPC"
  }
}
