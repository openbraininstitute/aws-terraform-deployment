module "storage" {
  source = "./storage"

  subnet_id                = var.subnet_id
  subnet_security_group_id = var.subnet_security_group_id
  blazegraph_efs_name      = var.blazegraph_efs_name
  efs_blazegraph_data_dir  = var.efs_blazegraph_data_dir

}

module "ecs" {
  source = "./ecs"

  count = var.is_blazegraph_running ? 1 : 0

  subnet_id                                = var.subnet_id
  subnet_security_group_id                 = var.subnet_security_group_id
  ecs_cluster_arn                          = var.ecs_cluster_arn
  aws_service_discovery_http_namespace_arn = var.aws_service_discovery_http_namespace_arn
  ecs_task_execution_role_arn              = var.ecs_task_execution_role_arn
  dockerhub_credentials_arn                = var.dockerhub_credentials_arn
  blazegraph_cpu                           = var.blazegraph_cpu
  blazegraph_memory                        = var.blazegraph_memory
  blazegraph_java_opts                     = var.blazegraph_java_opts
  blazegraph_instance_name                 = var.blazegraph_instance_name
  blazegraph_log_group_name                = aws_cloudwatch_log_group.blazegraph_app.name

  blazegraph_port                           = var.blazegraph_port
  blazegraph_docker_image_url               = var.blazegraph_docker_image_url
  aws_efs_access_point_blazegraph_id        = module.storage.aws_efs_access_point_blazegraph_id
  aws_efs_access_point_blazegraph_config_id = module.storage.aws_efs_access_point_blazegraph_config_id

  aws_efs_file_system_blazegraph_config_id = module.storage.aws_efs_file_system_blazegraph_config_id
  aws_efs_file_system_blazegraph_id        = module.storage.aws_efs_file_system_blazegraph_id
}

resource "aws_cloudwatch_log_group" "blazegraph_app" {
  name              = "${var.blazegraph_instance_name}_app"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key
}

