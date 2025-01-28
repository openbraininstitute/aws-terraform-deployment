moved {
  from = aws_apigatewayv2_api.this
  to   = module.bbp_workflow_svc.aws_apigatewayv2_api.this
}
moved {
  from = aws_route_table_association.bbp_workflow_svc
  to   = module.bbp_workflow_svc.aws_route_table_association.bbp_workflow_svc
}
moved {
  from = aws_security_group.bbp_workflow_svc
  to   = module.bbp_workflow_svc.aws_security_group.bbp_workflow_svc
}
moved {
  from = aws_subnet.bbp_workflow_svc
  to   = module.bbp_workflow_svc.aws_subnet.bbp_workflow_svc
}
