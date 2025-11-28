
data "aws_eks_cluster" "jupyterhub" {
  count = var.is_staging ? 1 : 0
  name  = var.jupyterhub_eks_cluster_name
}
