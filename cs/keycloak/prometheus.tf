resource "aws_prometheus_workspace" "keycloak-managed-prometheus-workspace" {
  alias = "keycloak"

  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_prometheus_workspace" "jupyterhub-managed-prometheus-workspace" {
  alias = "jupyterhub"

  tags = {
    SBO_Billing = "jupyterhub_svc"
  }
}
