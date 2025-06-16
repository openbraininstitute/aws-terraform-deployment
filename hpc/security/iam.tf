resource "aws_iam_role" "hpc_resource_provisioner_role" {
  name = "hpc_resource_provisioner_role"

  assume_role_policy = file("${path.module}/hpc_resource_provisioner_assume_role_policy.json")
}

resource "aws_iam_policy" "hpc_resource_provisioner_policy" {
  name   = "hpc_resource_provisioner_policy"
  policy = templatefile("${path.module}/hpc_resource_provisioner_policy.tftpl", { "account_id" = var.account_id, "aws_region" = var.aws_region })
}

resource "aws_iam_policy" "hpc_resource_provisioner_policy_2" {
  name   = "hpc_resource_provisioner_policy_2"
  policy = templatefile("${path.module}/hpc_resource_provisioner_policy_2.tftpl", { "account_id" = var.account_id, "aws_region" = var.aws_region })
}

resource "aws_iam_role_policy_attachment" "hpc_resource_provisioner_role_policy_attachment" {
  role       = aws_iam_role.hpc_resource_provisioner_role.name
  policy_arn = aws_iam_policy.hpc_resource_provisioner_policy.arn
}

resource "aws_iam_role_policy_attachment" "hpc_resource_provisioner_role_policy_attachment_2" {
  role       = aws_iam_role.hpc_resource_provisioner_role.name
  policy_arn = aws_iam_policy.hpc_resource_provisioner_policy_2.arn
}

resource "aws_iam_policy" "fsx_describe_dra_policy" {
  name   = "fsx_describe_dra_policy"
  policy = file("${path.module}/pcluster_fsx_policy.json")
}

resource "aws_iam_role" "resource_provisioner_eventbridge" {
  name               = "hpc_resource_provisioner_eventbridge_role"
  assume_role_policy = file("${path.module}/hpc_resource_provisioner_eventbridge_assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "resource_provisioner_eventbridge" {
  role       = aws_iam_role.resource_provisioner_eventbridge.name
  policy_arn = aws_iam_policy.resource_provisioner_eventbridge.arn
}

resource "aws_iam_policy" "resource_provisioner_eventbridge" {
  name   = "eventbridge_fire_lambda_policy"
  policy = templatefile("${path.module}/hpc_resource_provisioner_eventbridge_policy.tftpl", { "account_id" = var.account_id, "aws_region" = var.aws_region })
}
