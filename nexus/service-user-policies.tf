locals {
  nexus_service_user_name = "nexus-service-user"
}

#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "nexus-service-user" {
  name = local.nexus_service_user_name
}

#tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "ecs-group" {
  name = "ECS"
}

# Being a member of this group allows full access to the ECS actions
resource "aws_iam_user_group_membership" "groups" {
  groups = [aws_iam_group.ecs-group.name]
  user   = aws_iam_user.nexus-service-user.name
}

# Allows read access to the whole third-party AWS Marketplace
# This is where we can connect the account to the Elastic Cloud
# third party service. Since this is read-only, management of the
# connection has to be done with the administrator account.
resource "aws_iam_user_policy_attachment" "AWSMarketplaceRead-only" {
  policy_arn = "arn:aws:iam::aws:policy/AWSMarketplaceRead-only"
  user       = aws_iam_user.nexus-service-user.name
}

# Allows read only access to the whole AWS Console
resource "aws_iam_user_policy_attachment" "ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  user       = aws_iam_user.nexus-service-user.name
}

# Allows to access all secrets that start with "nexus"
resource "aws_iam_user_policy_attachment" "nexus_secrets_access" {
  policy_arn = module.iam.nexus_secret_access_policy_arn
  user       = aws_iam_user.nexus-service-user.name
}

# Allows full access to the S3 buckets for which the name start with "nexus"
#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_user_policy" "nexus_s3_access" {
  name = "NexusS3Access"
  user = aws_iam_user.nexus-service-user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "s3:Get*",
          "s3:List*",
          "s3:Copy*",
          "s3:Put*"
        ]
        Effect : "Allow"
        Resource : [
          "arn:aws:s3:::nexus*",
          "arn:aws:s3:::nexus*/*"
        ]
      }
    ]
  })
}

# Allow necessary actions on RDS nexus instances
resource "aws_iam_user_policy" "nexus_rds_access" {
  name = "NexusRDSAccess"
  user = aws_iam_user.nexus-service-user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "rds:ModifyRecommendation",
          "rds:ModifyDBRecommendation",
          "rds:CancelExportTask",
          "rds:DescribeDBRecommendations",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeExportTasks",
          "rds:StartExportTask",
          "rds:DescribeEngineDefaultParameters",
          "rds:DescribeRecommendations",
          "rds:DescribeReservedDBInstancesOfferings",
          "rds:ModifyCertificates",
          "rds:DescribeRecommendationGroups",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeEngineDefaultClusterParameters",
          "rds:DescribeSourceRegions",
          "rds:DescribeCertificates",
          "rds:DescribeEventCategories",
          "rds:DescribeAccountAttributes",
          "rds:DescribeEvents"
        ]
        Effect : "Allow"
        Resource : "*"
      },
      {
        Action : "rds:*",
        Effect : "Allow",
        Resource : "arn:aws:rds:${var.aws_region}:${var.account_id}:*:nexus*"
      }
    ]
  })
}

# Allows full access to the lambda functions for which the name start with "nexus"
resource "aws_iam_user_policy" "nexus_lambda_access" {
  name = "NexusLambdaAccess"
  user = aws_iam_user.nexus-service-user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : "lambda:*"
        Effect : "Allow"
        Resource : "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:nexus*"
      }
    ]
  })
}
