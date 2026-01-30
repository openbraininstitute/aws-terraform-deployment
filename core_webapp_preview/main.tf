data "aws_caller_identity" "current" {}

resource "aws_iam_role" "amplify_service" {
  name = "${var.app_name}-amplify-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "amplify.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "amplify_service" {
  name = "${var.app_name}-amplify-service-policy"
  role = aws_iam_role.amplify_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_arn
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZones"
        Resource = "*"
      }
    ]
  })
}

resource "aws_amplify_app" "this" {
  name       = var.app_name
  repository = var.repository_url
  platform   = "WEB_COMPUTE"

  iam_service_role_arn = aws_iam_role.amplify_service.arn

  access_token = var.github_access_token

  environment_variables = {
    API_ORIGIN             = var.api_origin
    DEPLOYMENT_ENV         = var.deployment_env
    KEYCLOAK_ISSUER        = var.keycloak_issuer
    SANITY_DATASET         = var.sanity_dataset
    STRIPE_PUBLISHABLE_KEY = var.stripe_publishable_key
    KEYCLOAK_CLIENT_ID     = var.secrets_arn
    KEYCLOAK_CLIENT_SECRET = var.secrets_arn
    NEXTAUTH_SECRET        = var.secrets_arn
  }

  enable_branch_auto_build    = true
  enable_auto_branch_creation = true
  enable_branch_auto_deletion = true
}

resource "aws_amplify_branch" "default" {
  app_id      = aws_amplify_app.this.id
  branch_name = var.default_branch

  enable_auto_build = true
}

resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.this.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = "main"
    prefix      = "main"
  }

  sub_domain {
    branch_name = "develop"
    prefix      = "dev"
  }

  enable_auto_sub_domain = true
}

resource "aws_iam_role" "github_deploy" {
  name = "${var.app_name}-github-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "${var.app_name}-github-deploy-policy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "amplify:GetBranch",
          "amplify:ListBranches",
          "amplify:StartJob",
          "amplify:GetJob",
          "amplify:ListJobs",
          "amplify:CreateDeployment",
          "amplify:StartDeployment",
          "amplify:CreateBranch"
        ]
        Resource = "${aws_amplify_app.this.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "amplify:GetApp"
        ]
        Resource = aws_amplify_app.this.arn
      }
    ]
  })
}
