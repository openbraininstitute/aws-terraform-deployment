resource "aws_subnet" "me_model_analysis_ec2" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.15.0/24"

  tags = {
    Name        = "me-model-analysis-ec2"
    SBO_Billing = "me_model_analysis"
  }
}

resource "aws_subnet" "me_model_analysis_ecs" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.14.0/24"

  tags = {
    Name        = "me-model-analysis-ecs"
    SBO_Billing = "me_model_analysis"
  }
}

resource "aws_route_table_association" "me_model_analysis_ec2" {
  subnet_id      = aws_subnet.me_model_analysis_ec2.id
  route_table_id = var.route_table_id
}

resource "aws_route_table_association" "me_model_analysis_ecs" {
  subnet_id      = aws_subnet.me_model_analysis_ecs.id
  route_table_id = var.route_table_id
}
