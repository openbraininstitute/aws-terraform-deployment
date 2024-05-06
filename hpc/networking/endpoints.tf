# Create VPC Endpoints for private access to CloudWatch, CloudFormation, EC2, S3, and DynamoDB
# According to https://repost.aws/knowledge-center/ec2-systems-manager-vpc-endpoints
# not every subnet neets an endpoint, the endpoint just needs to be in the same AZ as the subnet.
# In fact, it is an error to create an endpoint more than once in the same availability zone.
# We now have dedicated subnets for the endpoints (accessible from the compute subnets), one per
# availability zone.

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.us-east-1.monitoring"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "cloudwatch endpoint"
  }
}
resource "aws_vpc_endpoint" "cloudformation" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.us-east-1.cloudformation"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "cloudformation endpoint"
  }
}
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.aws_subnet_compute_endpoints_ids
  security_group_ids  = var.security_groups
  tags = {
    Name = "ec2 endpoint"
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = var.pcluster_vpc_id
  service_name    = "com.amazonaws.us-east-1.s3"
  route_table_ids = aws_route_table.compute[*].id
  tags = {
    Name = "s3 endpoint"
  }
}
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = var.pcluster_vpc_id
  service_name    = "com.amazonaws.us-east-1.dynamodb"
  route_table_ids = aws_route_table.compute[*].id
  tags = {
    Name = "dynamodb endpoint"
  }
}
