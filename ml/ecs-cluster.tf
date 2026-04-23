#tfsec:ignore:aws-ecs-enable-container-insight
module "ml_ecs_cluster" {
  source       = "terraform-aws-modules/ecs/aws//modules/cluster"
  version      = "v5.12.1"
  cluster_name = local.ecs_cluster_name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
  cluster_settings = [{ "name" : "containerInsights", "value" : "disabled" }]
  tags             = var.tags
}
