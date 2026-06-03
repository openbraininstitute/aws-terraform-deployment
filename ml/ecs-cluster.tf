#tfsec:ignore:aws-ecs-enable-container-insight
module "ml_ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "v6.12.0"
  name    = local.ecs_cluster_name

  # Capacity provider
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }
  setting = [{ "name" : "containerInsights", "value" : "disabled" }]
  tags    = var.tags
}
