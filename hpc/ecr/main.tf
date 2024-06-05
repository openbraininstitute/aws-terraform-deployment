# tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "hpc_containers" {
  name = "hpc-resource-provisioner"
  # mutable, because otherwise we can't update `latest`
  # see https://github.com/aws/containers-roadmap/issues/878
  image_tag_mutability = "MUTABLE" # tfsec:ignore:aws-ecr-enforce-immutable-repository
  image_scanning_configuration {
    scan_on_push = false # tfsec:ignore:aws-ecr-enable-image-scans
  }
}
