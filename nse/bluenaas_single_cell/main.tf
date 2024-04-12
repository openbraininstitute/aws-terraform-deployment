module "single_cell" {
  source              = "../../on_demand_svc"
  svc_name            = "single-cell"
  vpc_id              = var.vpc_id
  aws_region          = var.aws_region
  ec2_subnet_id       = aws_subnet.bluenaas_single_cell_ec2.id
  ec2_image_id        = var.amazon_linux_ecs_ami_id
  ecs_subnet_id       = aws_subnet.bluenaas_single_cell_ecs.id
  dockerhub_creds_arn = var.dockerhub_credentials_arn
  account_id          = var.account_id
  svc_image           = var.docker_image_url
  svc_bucket          = "sbo-cell-svc-perf-test"
  tags                = { SBO_Billing = "bluenaas_single_cell" }
}
