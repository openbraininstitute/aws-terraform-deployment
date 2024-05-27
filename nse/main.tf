module "bluenaas_single_cell" {
  source = "./bluenaas_single_cell"

  aws_region                = var.aws_region
  account_id                = var.account_id
  vpc_id                    = var.vpc_id
  docker_image_url          = var.single_cell_docker_image_url
  dockerhub_credentials_arn = var.dockerhub_credentials_arn

  amazon_linux_ecs_ami_id = var.amazon_linux_ecs_ami_id
  route_table_id          = var.route_table_id
}


module "me_model_analysis" {
  source = "./me_model_analysis"

  aws_region                = var.aws_region
  account_id                = var.account_id
  vpc_id                    = var.vpc_id
  docker_image_url          = var.me_model_analysis_docker_image_url
  dockerhub_credentials_arn = var.dockerhub_credentials_arn

  amazon_linux_ecs_ami_id = var.amazon_linux_ecs_ami_id
  route_table_id          = var.route_table_id
}
