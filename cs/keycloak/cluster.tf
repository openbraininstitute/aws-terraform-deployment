### ECS cluster
#tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "keycloak-cluster" {
  name = "keycloak-cluster"

  tags = {
    SBO_Billing = "keycloak"
  }
}
