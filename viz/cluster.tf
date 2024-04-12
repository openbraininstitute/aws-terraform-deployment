resource "aws_ecs_cluster" "viz" {
  name = "viz_ecs_cluster"

  tags = {
    Application = "viz"
    SBO_Billing = "viz"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}
