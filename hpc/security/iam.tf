resource "aws_iam_role" "hpc_resource_provisioner_role" {
  name = "hpc_resource_provisioner_role"

  assume_role_policy = file("${path.module}/hpc_resource_provisioner_assume_role_policy.json")
}

resource "aws_iam_policy" "hpc_resource_provisioner_policy" {
  name   = "hpc_resource_provisioner_policy"
  policy = templatefile("${path.module}/hpc_resource_provisioner_policy.tftpl", { "account_id" = var.account_id })
}

resource "aws_iam_role_policy_attachment" "hpc_resource_provisioner_role_policy_attachment" {
  role       = aws_iam_role.hpc_resource_provisioner_role.name
  policy_arn = aws_iam_policy.hpc_resource_provisioner_policy.arn
}
