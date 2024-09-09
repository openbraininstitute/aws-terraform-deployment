
resource "aws_iam_policy" "hpc_pcluster_ami_policy" {
  name = "SBOInfrastructureAssets_S3GetObject_RPMs"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::sboinfrastructureassets/rpms/*"
      }
    ]
  })

  tags = {
    SBO_Billing = "hpc:parallelcluster"
  }
}
