resource "aws_ecs_cluster" "nexus" {
  name  = "nexus_ecs_cluster"
  count = var.is_nexus_obp_running ? 1 : 0
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_service_discovery_http_namespace" "nexus" {
  name        = "nexus"
  count       = var.is_nexus_obp_running ? 1 : 0
  description = "nexus service discovery namespace"
}

resource "aws_ecs_cluster" "nexus_openscience" {
  name  = "nexus_openscience_ecs_cluster"
  count = var.is_nexus_openscience_running ? 1 : 0
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_service_discovery_http_namespace" "nexus_openscience" {
  name        = "nexus_openscience"
  count       = var.is_nexus_openscience_running ? 1 : 0
  description = "nexus openscience service discovery namespace"
}

