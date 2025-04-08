resource "aws_iam_policy" "iam_build_policy" {
  name        = "gh_build_ami"
  description = "Policy to allow any actions needed to build AMIs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/**",
        ]
      },
      {
        "Action" : [
          "cloudformation:DeleteStack",
          "cloudformation:ListStacks"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:cloudformation:${var.aws_region}:${var.account_id}:stack/obi-parallelcluster*/*",
          "arn:aws:cloudformation:${var.aws_region}:${var.account_id}:stack/*/*",
        ]
      },
      {
        "Action" : [
          "imagebuilder:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image/obi-parallelcluster-*/*/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/packages/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/neurodamus-toolchain/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/singularity-ce/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/configure-ami/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/parallelclusterimage-updateos*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/parallelclusterimage*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image/parallelclusterimage-obi*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:infrastructure-configuration/parallelclusterimage*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:distribution-configuration/parallelclusterimage*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image-recipe/parallelclusterimage-obi*"
        ]
      },
      {
        "Action" : [
          "lambda:DeleteFunction",
          "lambda:RemovePermission"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:ParallelClusterImage*"
        ]
      },
      {
        "Action" : [
          "ec2:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:ec2:${var.aws_region}::image/*",
        ]
      },
      {
        "Action" : [
          "iam:RemoveRoleFromInstanceProfile"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::${var.account_id}:policy/ParallelCluster_S3_GetObject_RPMs"
        ]
      },
      {
        "Action" : [
          "SNS:DeleteTopic",
          "SNS:GetTopicAttributes",
          "SNS:Unsubscribe"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:sns:${var.aws_region}:${var.account_id}:ParallelClusterImage*"
        ]
      },
      {
        "Action" : [
          "imagebuilder:ListComponents"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/*"
        ]
      },
      {
        "Action" : [
          "logs:DeleteLogGroup"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/ParallelClusterImage*"
        ]
      },
      {
        "Action" : [
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeSecurityGroups",
          "cloudformation:DescribeStacks",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:RemoveRoleFromInstanceProfile"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

module "github_oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
  create_oidc_role     = true
  role_name            = "GithubMachineImages"

  repositories              = ["openbraininstitute/machine-images"]
  oidc_role_attach_policies = [aws_iam_policy.iam_build_policy.arn]
}
