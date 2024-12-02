resource "aws_ecs_cluster" "nexus" {
  name = "nexus_ecs_cluster"
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_service_discovery_http_namespace" "nexus" {
  name        = "nexus"
  description = "nexus service discovery namespace"
}

resource "aws_ecs_cluster" "nexus_openscience" {
  name = "nexus_openscience_ecs_cluster"
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_service_discovery_http_namespace" "nexus_openscience" {
  name        = "nexus_openscience"
  description = "nexus openscience service discovery namespace"
}