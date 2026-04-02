
data "aws_eks_cluster" "jupyterhub" {
  count = var.is_staging ? 1 : 1
  name  = var.jupyterhub_eks_cluster_name
  tags  = { SBO_Billing = "jupyterhub_svc" }
}
