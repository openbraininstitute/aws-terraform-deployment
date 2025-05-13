resource "aws_prometheus_workspace" "keycloak-managed-prometheus-workspace" {
  alias = "keycloak"

  tags = {
    SBO_Billing = "keycloak"
  }
}
