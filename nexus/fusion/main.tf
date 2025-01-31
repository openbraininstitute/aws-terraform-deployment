module "ecs" {
  source = "./ecs"
  count  = var.is_fusion_running ? 1 : 0

  aws_region                                   = var.aws_region
  subnet_id                                    = var.subnet_id
  subnet_security_group_id                     = var.subnet_security_group_id
  ecs_cluster_arn                              = var.ecs_cluster_arn
  aws_service_discovery_http_namespace_arn     = var.aws_service_discovery_http_namespace_arn
  nexus_fusion_hostname                        = var.nexus_fusion_hostname
  nexus_fusion_base_path                       = var.nexus_fusion_base_path
  nexus_fusion_docker_image_url                = var.nexus_fusion_docker_image_url
  nexus_fusion_client_id                       = var.nexus_fusion_client_id
  nexus_delta_endpoint                         = var.nexus_delta_endpoint
  ecs_task_execution_role_arn                  = var.ecs_task_execution_role_arn
  private_aws_lb_target_group_nexus_fusion_arn = var.private_aws_lb_target_group_nexus_fusion_arn
  dockerhub_credentials_arn                    = var.dockerhub_credentials_arn
  fusion_instance_name                         = var.fusion_instance_name
  aws_cloudwatch_log_group_nexus_fusion_arn    = aws_cloudwatch_log_group.nexus_fusion.arn

}

resource "aws_cloudwatch_log_group" "nexus_fusion" {
  name              = var.fusion_instance_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key
}
