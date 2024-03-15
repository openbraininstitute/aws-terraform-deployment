resource "aws_subnet" "bbp_aws_svc_ec2" {
  vpc_id            = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.3.32/28"

  tags = {
    Name        = "bbp-aws-svc-ec2"
    SBO_Billing = "bbp_aws_svc"
  }
}

resource "aws_subnet" "bbp_aws_svc_ecs" {
  vpc_id            = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.3.64/28"

  tags = {
    Name        = "bbp-aws-svc-ecs"
    SBO_Billing = "bbp_aws_svc"
  }
}

# ECS agent on EC2 probably needs routing to NAT to be able to start ECS tasks
# could be external docker image, not clear what exactly fails without this
resource "aws_route_table_association" "bbp_aws_svc_ec2" {
  subnet_id      = aws_subnet.bbp_aws_svc_ec2.id
  route_table_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}

# Needs access to public apigateway
# https://repost.aws/knowledge-center/api-gateway-vpc-connections:
# Important: Resources in your VPC that try to connect to your public APIs must have internet connectivity.
resource "aws_route_table_association" "bbp_aws_svc_ecs" {
  subnet_id      = aws_subnet.bbp_aws_svc_ecs.id
  route_table_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}
