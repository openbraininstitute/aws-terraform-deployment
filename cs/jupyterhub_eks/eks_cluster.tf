
data "aws_eks_cluster" "jupyterhub" {
  name = var.jupyterhub_eks_cluster_name
}
