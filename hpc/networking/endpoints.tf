# Create VPC Endpoints for private access to CloudWatch, CloudFormation, EC2, S3, and DynamoDB
# According to https://repost.aws/knowledge-center/ec2-systems-manager-vpc-endpoints
# not every subnet neets an endpoint, the endpoint just needs to be in the same AZ as the subnet.
# In fact, it is an error to create an endpoint more than once in the same availability zone.
# We now have dedicated subnets for the endpoints (accessible from the compute subnets), one per
# availability zone.

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "Parallel-Clusters CloudWatch Endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "Parallel-Clusters CloudWatch Logs Endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudformation" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.cloudformation"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "Parallel-Clusters CloudFormation Endpoint"
  }
}
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "Parallel-Clusters EC2 Endpoint"
  }
}

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = var.pcluster_vpc_id
#   service_name        = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   subnet_ids          = local.aws_subnet_compute_endpoints_ids
#   security_group_ids  = var.security_groups
#   tags = {
#     Name = "Parallel-Clusters SSM Endpoint"
#   }
# }

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = var.pcluster_vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.compute.id, data.aws_route_table.default_route_table.id]
  tags = {
    Name = "Parallel-Cluster S3 Endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = var.pcluster_vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [aws_route_table.compute.id, data.aws_route_table.default_route_table.id]
  tags = {
    Name = "Parallel-Clusters DynamoDB Endpoint"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags                = { Name = "Parallel-Clusters SecretsManager Endpoint" }
}
