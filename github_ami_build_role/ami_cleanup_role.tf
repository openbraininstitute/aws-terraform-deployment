resource "aws_iam_role" "cleanup_lambda_role" {
  name = "CleanupLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "iam_cleanup_policy" {
  name        = "cleanup_lambda"
  description = "Policy to allow any actions needed to clean up after building AMIs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "iam:DetachRolePolicy",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy"
        ],
        Resource = "arn:aws:iam::${var.account_id}:role/parallelcluster/*",
        Effect   = "Allow"
      },
      {
        Action = [
          "iam:DeleteInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ],
        Resource = "arn:aws:iam::${var.account_id}:instance-profile/parallelcluster/*",
        Effect   = "Allow"
      },
      {
        Action   = "imagebuilder:DeleteInfrastructureConfiguration",
        Resource = "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:infrastructure-configuration/parallelclusterimage-*",
        Effect   = "Allow"
      },
      {
        Action = [
          "imagebuilder:DeleteComponent"
        ],
        Resource = [
          "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:component/parallelclusterimage-*/*"
        ],
        Effect = "Allow"
      },
      {
        Action   = "imagebuilder:DeleteImageRecipe",
        Resource = "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image-recipe/parallelclusterimage-*/*",
        Effect   = "Allow"
      },
      {
        Action   = "imagebuilder:DeleteDistributionConfiguration",
        Resource = "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:distribution-configuration/parallelclusterimage-*",
        Effect   = "Allow"
      },
      {
        Action = [
          "imagebuilder:DeleteImage",
          "imagebuilder:GetImage",
          "imagebuilder:CancelImageCreation"
        ],
        Resource = "arn:aws:imagebuilder:${var.aws_region}:${var.account_id}:image/parallelclusterimage-*/*",
        Effect   = "Allow"
      },
      {
        Action   = "cloudformation:DeleteStack",
        Resource = "arn:aws:cloudformation:${var.aws_region}:${var.account_id}:stack/*/*",
        Effect   = "Allow"
      },
      {
        Action   = "ec2:CreateTags",
        Resource = "arn:aws:ec2:${var.aws_region}::image/*",
        Effect   = "Allow"
      },
      {
        Action   = "tag:TagResources",
        Resource = "*",
        Effect   = "Allow"
      },
      {
        Action = [
          "lambda:DeleteFunction",
          "lambda:RemovePermission"
        ],
        Resource = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:ParallelClusterImage-*",
        Effect   = "Allow"
      },
      {
        Action   = "logs:DeleteLogGroup",
        Resource = "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/ParallelClusterImage-*:*",
        Effect   = "Allow"
      },
      {
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:GetSubscriptionAttributes",
          "SNS:Unsubscribe"
        ],
        Resource = "arn:aws:sns:${var.aws_region}:${var.account_id}:ParallelClusterImage-*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_cleanup_policy" {
  role       = aws_iam_role.cleanup_lambda_role.name
  policy_arn = aws_iam_policy.iam_cleanup_policy.arn
}
