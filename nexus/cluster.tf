resource "aws_ecs_cluster" "nexus" {
  name = "nexus_ecs_cluster"
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
  tags = {
    SBO_Billing = "nexus"
  }
}

resource "aws_service_discovery_http_namespace" "nexus" {
  name        = "nexus"
  description = "nexus service discovery namespace"

  tags = {
    SBO_Billing = "nexus"
  }
}