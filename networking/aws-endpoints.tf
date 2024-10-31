# Goal: create an endpoint for the secretsmanager within the VPC, so that
# ECS can access the secret to download the dockerhub credentials to access
# our private repositories from within the VPC.
# https://aws.amazon.com/blogs/security/how-to-connect-to-aws-secrets-manager-service-within-a-virtual-private-cloud/

# TODO Not yet working. Likely somehow ECS containers have to be switched from public DNS to private DNS.
# See also https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
# DNS server should be at 10.0.0.2 . Also to check: enable_dns_hostnames option in aws_pvc.

# 10.0.2.16/28 is 10.0.2.16 up to 10.0.2.31 with subnet and broadcast included
resource "aws_subnet" "aws_endpoints" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.16/28"
  map_public_ip_on_launch = false

  tags = { Name = "VPC Endpoints Subnet" }
}

# Link route table to aws_endpoints network
resource "aws_route_table_association" "aws_endpoints" {
  subnet_id      = aws_subnet.aws_endpoints.id
  route_table_id = var.route_table_id
}

resource "aws_network_acl" "aws_endpoints" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.aws_endpoints.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  /* # Allow temporarily all
  ingress {
    protocol = -1
    rule_no = 101
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }*/
  # allow ingress ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    # TODO probably egress not needed at all?
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = { Name = "VPC Endpoints ACL" }
}

resource "aws_security_group" "aws_endpoints_sg" {
  name        = "VPC Endpoints Security Group"
  vpc_id      = var.vpc_id
  description = "Security Group for the VPC Endpoints of the OBP VPC"
  tags        = { Name = "VPC Endpoints Security Group" }
}

# TODO could be limited to just certain private subnets?
resource "aws_vpc_security_group_ingress_rule" "aws_endpoints_sgr_ingress" {
  security_group_id = aws_security_group.aws_endpoints_sg.id
  description       = "Allow all incoming from VPC"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
  tags              = { Name = "VPC Endpoints Security Group Rule - Ingress" }
}

# TODO limit to certain services
# probably egress not needed at all?
resource "aws_vpc_security_group_egress_rule" "aws_endpoints_sgr_egress" {
  security_group_id = aws_security_group.aws_endpoints_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "VPC Endpoints Security Group Rule - Egress" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "SecretsManager Endpoint" }
}

resource "aws_vpc_endpoint" "cloudwatch" {
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "CloudWatch Endpoint" }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "CloudWatch Logs Endpoint" }
}

resource "aws_vpc_endpoint" "cloudformation" {
  service_name        = "com.amazonaws.${var.aws_region}.cloudformation"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "CloudFormation Endpoint" }
}

resource "aws_vpc_endpoint" "ec2" {
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "EC2 Endpoint" }
}

resource "aws_vpc_endpoint" "efs" {
  service_name        = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "EFS Endpoint" }
}

resource "aws_vpc_endpoint" "s3" {
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = var.vpc_id
  route_table_ids   = [var.route_table_id]
  tags              = { Name = "S3 Endpoint (Gateway)" }
}

resource "aws_vpc_endpoint" "s3express" {
  service_name      = "com.amazonaws.${var.aws_region}.s3express"
  vpc_endpoint_type = "Gateway"
  vpc_id            = var.vpc_id
  route_table_ids   = [var.route_table_id]
  tags              = { Name = "S3 Express One Zone Endpoint" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  vpc_id            = var.vpc_id
  route_table_ids   = [var.route_table_id]
  tags              = { Name = "DynamoDB Endpoint" }
}

resource "aws_vpc_endpoint" "ssm" {
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "SSM Endpoint" }
}

resource "aws_vpc_endpoint" "sts" {
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "STS Endpoint" }
}

resource "aws_vpc_endpoint" "lambda" {
  service_name        = "com.amazonaws.${var.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [aws_subnet.aws_endpoints.id]
  security_group_ids  = [aws_security_group.aws_endpoints_sg.id]
  private_dns_enabled = true
  tags                = { Name = "Lambda Endpoint" }
}
