module "ml_ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "ml-repository"
  repository_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last 3 images for neuroagent",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPrefixList" : ["neuroagent"],
          "countType" : "imageCountMoreThan",
          "countNumber" : 3
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 2,
        "description" : "Keep only the last 3 images for scholarag",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPrefixList" : ["scholarag"],
          "countType" : "imageCountMoreThan",
          "countNumber" : 3
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 3,
        "description" : "Keep only the last 3 images for scholaretl",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPrefixList" : ["scholaretl"],
          "countType" : "imageCountMoreThan",
          "countNumber" : 3
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
    }
  )
  tags = var.tags
}

resource "aws_iam_policy" "ml_gh_policy" {
  name        = "GithubECRPushPolicy"
  description = "Policy to allow push access to the specified ECR repository"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:PutImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
        ]
        Effect   = "Allow"
        Resource = module.ml_ecr.repository_arn
      },
      {
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


module "ml_github_oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  create_oidc_provider = true
  create_oidc_role     = true
  role_name            = "GitHub2ECR"

  repositories              = var.github_repos
  oidc_role_attach_policies = [aws_iam_policy.ml_gh_policy.arn]
}