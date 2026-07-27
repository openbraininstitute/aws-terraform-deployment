resource "aws_iam_policy" "iam_build_policy" {
  name        = "gh_build_ami"
  description = "Policy to allow any actions needed to build AMIs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPolicy",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::parallelcluster-*-v1-do-not-delete",
          "arn:aws:s3:::parallelcluster-*-v1-do-not-delete/*"
        ]
      },
      {
        "Action" : [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:cloudformation:${var.aws_region}:${var.account_id}:stack/obi-parallelcluster*/*"
        ]
      },
      {
        "Action" : [
          "cloudformation:ListStacks"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:cloudformation:${var.aws_region}:${var.account_id}:stack/*/*"
        ]
      },
      {
        "Action" : [
          "imagebuilder:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image/obi-parallelcluster-*/*/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image/parallelclusterimage-obi*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:infrastructure-configuration/parallelclusterimage*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:distribution-configuration/parallelclusterimage*",
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image-recipe/*",
          "arn:aws:imagebuilder:${var.aws_region}:*:image/amazon-linux-2023-x86*"
        ]
      },
      {
        "Action" : [
          "lambda:AddPermission",
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:DeleteFunction",
          "lambda:RemovePermission",
          "lambda:TagResource"
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
          "arn:aws:ec2:${var.aws_region}::snapshot/*"
        ]
      },
      {
        "Action" : [
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateRole",
          "iam:CreateInstanceProfile",
          "iam:CreateServiceLinkedRole",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:GetPolicy",
          "iam:GetRole",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagRole",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:UpdateRole"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::${var.account_id}:policy/ParallelCluster_S3_GetObject_RPMs",
          "arn:aws:iam::${var.account_id}:role/parallelcluster/ParallelClusterImage*",
          "arn:aws:iam::${var.account_id}:role/ParallelClusterImage*",
          "arn:aws:iam::${var.account_id}:instance-profile/ParallelClusterImage*",
          "arn:aws:iam::${var.account_id}:instance-profile/parallelcluster*",
          "arn:aws:iam::${var.account_id}:role/aws-service-role/imagebuilder.amazonaws.com*",
          "arn:aws:iam::${var.account_id}:role/CleanupLambdaRole"
        ]
      },
      {
        "Action" : [
          "SNS:CreateTopic",
          "SNS:DeleteTopic",
          "SNS:GetSubscriptionAttributes",
          "SNS:GetTopicAttributes",
          "SNS:Publish",
          "SNS:Subscribe",
          "SNS:TagResource",
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
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:TagResource"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/ParallelClusterImage*"
        ]
      },
      {
        "Action" : [
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeVolumes",
          "ec2:DescribeKeyPairs",
          "cloudformation:DescribeStacks"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateImage",
          "ec2:CreateTags",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:ec2:${var.aws_region}:${var.account_id}:instance/*",
          "arn:aws:ec2:${var.aws_region}:${var.account_id}:key-pair/packer_*",
          "arn:aws:ec2:${var.aws_region}:${var.account_id}:security-group/*",
          "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/*",
          "arn:aws:ec2:${var.aws_region}:${var.account_id}:network-interface/*",
          "arn:aws:ec2:${var.aws_region}:${var.account_id}:volume/*",
          "arn:aws:ec2:${var.aws_region}::image/*",
          "arn:aws:ec2:${var.aws_region}::snapshot/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "github_machine_images" {
  name = "GithubMachineImages"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        "ForAnyValue:StringLike" = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:openbraininstitute/machine-images:ref:refs/heads/main",
            "repo:openbraininstitute@*/machine-images@*:ref:refs/heads/main",
          ]
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_machine_images" {
  role       = aws_iam_role.github_machine_images.name
  policy_arn = aws_iam_policy.iam_build_policy.arn
}

moved {
  from = module.github_oidc.aws_iam_role.this[0]
  to   = aws_iam_role.github_machine_images
}

moved {
  from = module.github_oidc.aws_iam_role_policy_attachment.attach[0]
  to   = aws_iam_role_policy_attachment.github_machine_images
}
