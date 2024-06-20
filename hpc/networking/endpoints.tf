# Create VPC Endpoints for private access to CloudWatch, CloudFormation, EC2, S3, and DynamoDB
# According to https://repost.aws/knowledge-center/ec2-systems-manager-vpc-endpoints
# not every subnet neets an endpoint, the endpoint just needs to be in the same AZ as the subnet.
# In fact, it is an error to create an endpoint more than once in the same availability zone.
# We now have dedicated subnets for the endpoints (accessible from the compute subnets), one per
# availability zone.

resource "aws_default_route_table" "default" {
  default_route_table_id = data.aws_vpc.obp_vpc.main_route_table_id
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = var.pcluster_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
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
  service_name        = "com.amazonaws.${var.aws_region}.cloudformation"
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
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
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
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = aws_route_table.compute[*].id
  tags = {
    Name = "s3 endpoint"
  }
}
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = var.pcluster_vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = aws_route_table.compute[*].id
  tags = {
    Name = "dynamodb endpoint"
  }
}

# endpoints for the OBP VPC
# these are used by at least hpc-resource-provisioner

resource "aws_vpc_endpoint" "cloudformation_obp_endpoint" {
  vpc_id              = var.obp_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.cloudformation"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.lambda.id]
  security_group_ids  = [var.peering_sg_id, var.obp_vpc_default_sg_id, var.endpoints_sg_id]
  tags = {
    Name = "OBP VPC CloudFormation endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_obp_endpoint" {
  vpc_id              = var.obp_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.lambda.id]
  security_group_ids  = [var.peering_sg_id, var.obp_vpc_default_sg_id, var.endpoints_sg_id]
  tags = {
    Name = "OBP VPC CloudWatch endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_obp_endpoint" {
  vpc_id              = var.obp_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.lambda.id]
  security_group_ids  = [var.peering_sg_id, var.obp_vpc_default_sg_id, var.endpoints_sg_id]
  tags = {
    Name = "OBP VPC EC2 endpoint"
  }
}

resource "aws_vpc_endpoint" "efs_obp_endpoint" {
  vpc_id              = var.obp_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.lambda.id]
  security_group_ids  = [var.peering_sg_id, var.obp_vpc_default_sg_id, var.endpoints_sg_id]
  tags = {
    Name = "OBP VPC EFS endpoint"
  }
}

resource "aws_vpc_endpoint" "sts_obp_endpoint" {
  vpc_id              = var.obp_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.lambda.id]
  security_group_ids  = [var.peering_sg_id, var.obp_vpc_default_sg_id, var.endpoints_sg_id]
  tags = {
    Name = "OBP VPC STS endpoint"
  }
}

resource "aws_vpc_endpoint" "lambda_obp_endpoint" {
  vpc_id              = var.obp_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.lambda.id]
  security_group_ids  = [var.peering_sg_id, var.obp_vpc_default_sg_id, var.endpoints_sg_id]
  tags = {
    Name = "OBP VPC Lambda endpoint"
  }
}

resource "aws_vpc_endpoint" "s3_obp_endpoint" {
  vpc_id          = var.obp_vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_default_route_table.default.id]
  tags = {
    Name = "OBP VPC S3 endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb_obp_endpoint" {
  vpc_id          = var.obp_vpc_id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [aws_default_route_table.default.id]
  tags = {
    Name = "OBP VPC DynamoDB endpoint"
  }
}
