### ECS cluster
#tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "sbo-keycloak-cluster" {
  name = "sbo-keycloak-cluster"

  tags = {
    SBO_Billing = "keycloak"
  }
}
