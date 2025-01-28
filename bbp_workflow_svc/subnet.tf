resource "aws_subnet" "bbp_workflow_svc" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.19.0/24"

  tags = {
    Name        = "bbp-workflow-svc"
    SBO_Billing = "bbp_workflow_svc"
  }
}

resource "aws_route_table_association" "bbp_workflow_svc" {
  subnet_id      = aws_subnet.bbp_workflow_svc.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_security_group" "bbp_workflow_svc" {
  name        = "bbp-workflow-svc"
  description = "bbp-workflow-svc"
  vpc_id      = var.vpc_id
  tags        = { SBO_Billing = "bbp_workflow_svc" }
}

resource "aws_apigatewayv2_api" "this" {
  name          = "bbp-workflow-svc"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins     = ["http://{var.primary_domain}"]
    allow_methods     = ["POST", "GET"]
    allow_headers     = ["authorization"]
    allow_credentials = true
    max_age           = 300
  }
  tags = { SBO_Billing = "bbp_workflow_svc" }
}
