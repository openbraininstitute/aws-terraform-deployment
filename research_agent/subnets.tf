# Two new subnets inside the shared VPC, associated with the shared
# private route table (var.internet_access_route_id - already routes
# 0.0.0.0/0 via the shared NAT Gateway) - same pattern every other
# module in this repo uses to reuse the shared network rather than
# creating its own VPC/NAT. AgentCore's own `network_mode_config`
# expects a set of subnet ids across AZs, hence two, not one.
#
# AgentCore Runtime (VPC mode) only supports a subset of this region's
# AZs - confirmed the hard way: "us-east-1a" resolved to AZ ID
# use1-az6 in this account, which AWS rejected with "unsupported
# availability zone" at Runtime-create time (CREATE_FAILED), even
# though every other module in this repo happily uses "a"/"b". Picking
# by AZ ID instead of letter avoids relying on a per-account mapping.
#
# Changing availability_zone forces subnet replacement, and this
# provider version creates the replacement before destroying the old
# one rather than the reverse - so the CIDR here must differ from the
# previous attempt's (10.0.40.0/27, 10.0.40.32/27) or the create
# collides with the still-live old subnet ("CIDR conflicts with
# another subnet").
data "aws_availability_zones" "agentcore_supported" {
  state = "available"
  filter {
    name   = "zone-id"
    values = ["use1-az1", "use1-az2", "use1-az4"]
  }
}

resource "aws_subnet" "research_agent_a" {
  vpc_id            = var.vpc_id
  availability_zone = data.aws_availability_zones.agentcore_supported.names[0]
  cidr_block        = var.subnet_cidr_block_a
  tags = {
    Name = "research_agent_a"
  }
}

resource "aws_subnet" "research_agent_b" {
  vpc_id            = var.vpc_id
  availability_zone = data.aws_availability_zones.agentcore_supported.names[1]
  cidr_block        = var.subnet_cidr_block_b
  tags = {
    Name = "research_agent_b"
  }
}

resource "aws_route_table_association" "research_agent_a_routing" {
  subnet_id      = aws_subnet.research_agent_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "research_agent_b_routing" {
  subnet_id      = aws_subnet.research_agent_b.id
  route_table_id = var.internet_access_route_id
}

# The Runtime's own ENIs when network_mode = VPC. No inbound rule:
# invocation goes through AgentCore's own control/data-plane API
# (IAM/SigV4), never through this security group - it's purely for the
# Runtime's own outbound calls (Bedrock, notebook-service, eventually
# accounting-service).
resource "aws_security_group" "research_agent_runtime" {
  name        = "research_agent_runtime_vpc"
  description = "AgentCore Runtime own ENIs when network_mode is VPC"
  vpc_id      = var.vpc_id

  egress {
    description = "Full egress via the shared NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "research_agent_runtime_vpc"
  }
}
