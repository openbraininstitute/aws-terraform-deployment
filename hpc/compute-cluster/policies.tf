
resource "aws_iam_policy" "parallelcluster_rpms_policy" {
  name = "ParallelCluster_S3_GetObject_RPMs"

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
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "parallelcluster_cwlogs_policy" {
  name = "ParallelCluster_CloudWatch_TagLogGroup_SLURM"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:TagLogGroup",
        "Resource" : "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/parallelcluster/*.slurm-jobs"
      }
    ]
  })
}
