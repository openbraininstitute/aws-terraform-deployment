module "storage" {
  source = "./storage"

  subnet_id                = var.subnet_id
  delta_efs_name           = var.delta_efs_name
  subnet_security_group_id = var.subnet_security_group_id
}

module "ecs" {
  source = "./ecs"

  subnet_id                                = var.subnet_id
  delta_instance_name                      = var.delta_instance_name
  delta_cpu                                = var.delta_cpu
  delta_memory                             = var.delta_memory
  delta_java_opts                          = var.delta_java_opts
  desired_count                            = var.desired_count
  delta_config_file                        = var.delta_config_file
  delta_docker_image_version               = var.delta_docker_image_version
  s3_bucket_arn                            = var.s3_bucket_arn
  s3_bucket_name                           = var.s3_bucket_name
  postgres_host                            = var.postgres_host
  postgres_reader_host                     = var.postgres_reader_host
  elasticsearch_endpoint                   = var.elasticsearch_endpoint
  subnet_security_group_id                 = var.subnet_security_group_id
  ecs_cluster_arn                          = var.ecs_cluster_arn
  aws_service_discovery_http_namespace_arn = var.aws_service_discovery_http_namespace_arn
  ecs_task_execution_role_arn              = var.ecs_task_execution_role_arn
  nexus_secrets_arn                        = var.nexus_secrets_arn
  elastic_password_arn                     = var.elastic_password_arn
  private_delta_target_group_arn           = var.private_delta_target_group_arn
  delta_search_config_commit               = var.delta_search_config_commit
  dockerhub_credentials_arn                = var.dockerhub_credentials_arn
  blazegraph_endpoint                      = var.blazegraph_endpoint
  blazegraph_composite_endpoint            = var.blazegraph_composite_endpoint
  domain_name                              = var.domain_name

  aws_efs_file_system_delta_id         = module.storage.aws_efs_file_system_delta_id
  aws_efs_access_point_delta_config_id = module.storage.aws_efs_access_point_delta_config_id
  aws_efs_access_point_disk_storage_id = module.storage.aws_efs_access_point_disk_storage_id
}
