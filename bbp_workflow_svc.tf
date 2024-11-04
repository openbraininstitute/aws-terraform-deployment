resource "aws_subnet" "bbp_workflow_svc" {
  vpc_id            = local.vpc_id
  availability_zone = "${local.aws_region}a"
  cidr_block        = "10.0.19.0/24"

  tags = {
    Name        = "bbp-workflow-svc"
    SBO_Billing = "bbp_workflow_svc"
  }
}

resource "aws_route_table_association" "bbp_workflow_svc" {
  subnet_id      = aws_subnet.bbp_workflow_svc.id
  route_table_id = local.route_table_private_subnets_id
}

resource "aws_security_group" "bbp_workflow_svc" {
  name        = "bbp-workflow-svc"
  description = "bbp-workflow-svc"
  vpc_id      = local.vpc_id
  tags        = { SBO_Billing = "bbp_workflow_svc" }
}

resource "aws_apigatewayv2_api" "this" {
  name          = "bbp-workflow-svc"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins     = ["http://{local.primary_domain}"]
    allow_methods     = ["POST", "GET"]
    allow_headers     = ["authorization"]
    allow_credentials = true
    max_age           = 300
  }
}

module "bbp_workflow_svc" {
  source         = "./bbp_workflow_svc"
  svc_name       = "bbp-workflow-svc"
  vpc_id         = local.vpc_id
  aws_region     = local.aws_region
  ecs_subnet_id  = aws_subnet.bbp_workflow_svc.id
  ecs_secgrp_id  = aws_security_group.bbp_workflow_svc.id
  account_id     = local.account_id
  svc_image      = "bluebrain/bbp-workflow:latest"
  apigw_id       = aws_apigatewayv2_api.this.id
  primary_domain = local.primary_domain
  kc_scr         = "arn:aws:secretsmanager:eu-north-1:381492195897:secret:bbp-workflow-YJKyMV" # FIXME
  id_rsa_scr     = "arn:aws:secretsmanager:eu-north-1:381492195897:secret:hpc-id-rsa-2NNpPK"   # FIXME
  hpc_head_node  = "127.0.0.1"                                                                 # FIXME
  tags           = { SBO_Billing = "bbp_workflow_svc" }
}
