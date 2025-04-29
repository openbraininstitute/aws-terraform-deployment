### ECS cluster
#tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "keycloak-cluster" {
  name = var.keycloak_ecs_cluster_name

  tags = {
    SBO_Billing = "keycloak"
  }
}
