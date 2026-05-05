data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "secrets" {
  secret_id = var.secrets_arn
}

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
    }]
  })

  tags = {
    Name = "${var.app_name}-amplify-service-role"
  }
}

resource "aws_iam_role_policy" "amplify_service" {
  name = "${var.app_name}-amplify-service-policy"
  role = aws_iam_role.amplify_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PushLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/amplify/*:log-stream:*"
      },
      {
        Sid      = "CreateLogGroup"
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/amplify/*"
      },
      {
        Sid      = "DescribeLogGroups"
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
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
    _LIVE_PACKAGE_UPDATES  = "[{\"name\":\"Node.js version\",\"pkg\":\"node\",\"type\":\"nvm\",\"version\":\"24\"}]"
    API_ORIGIN             = var.api_origin
    DEPLOYMENT_ENV         = var.deployment_env
    KEYCLOAK_ISSUER        = var.keycloak_issuer
    SANITY_DATASET         = var.sanity_dataset
    STRIPE_PUBLISHABLE_KEY = var.stripe_publishable_key
    KEYCLOAK_CLIENT_ID     = var.keycloak_client_id
    KEYCLOAK_CLIENT_SECRET = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["client_secret_cellb_azure_staging"]
    NEXTAUTH_SECRET        = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["nextauth_secret"]
    AUTH_PROXY_URL         = "https://develop.${var.domain_name}"
  }

  enable_branch_auto_build    = false
  enable_auto_branch_creation = true
  enable_branch_auto_deletion = true

  auto_branch_creation_patterns = ["*", "*/**"]

  auto_branch_creation_config {
    enable_auto_build = false
  }

  tags = {
    Name = var.app_name
  }
}

resource "aws_amplify_branch" "default" {
  app_id      = aws_amplify_app.this.id
  branch_name = var.default_branch

  enable_auto_build = true

  tags = {
    Name = "${var.app_name}-${var.default_branch}"
  }
}

resource "aws_amplify_branch" "develop" {
  app_id      = aws_amplify_app.this.id
  branch_name = "develop"

  enable_auto_build = true

  tags = {
    Name = "${var.app_name}-develop"
  }
}

resource "aws_iam_role" "amplify_domain" {
  name = "AWSAmplifyDomainRole-${var.route53_zone_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "amplify.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "AWSAmplifyDomainRole-${var.route53_zone_id}"
  }
}

resource "aws_iam_role_policy" "amplify_domain" {
  name = "AWSAmplifyDomainPolicy-${var.route53_zone_id}"
  role = aws_iam_role.amplify_domain.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      }
    ]
  })
}

resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.this.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = var.default_branch
    prefix      = var.default_branch
  }

  sub_domain {
    branch_name = "develop"
    prefix      = "develop"
  }

  enable_auto_sub_domain = true

  lifecycle {
    ignore_changes = [sub_domain]
  }

  depends_on = [aws_iam_role_policy.amplify_domain]

  tags = {
    Name = var.domain_name
  }
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

  tags = {
    Name = "${var.app_name}-github-deploy-role"
  }
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
          "amplify:CreateBranch",
          "amplify:ListBranches",
          "amplify:GetBranch",
          "amplify:DeleteBranch",
          "amplify:StartJob",
          "amplify:StopJob",
          "amplify:GetJob",
          "amplify:ListJobs",
          "amplify:CreateDeployment",
          "amplify:StartDeployment",
          "amplify:GetDomainAssociation",
          "amplify:UpdateDomainAssociation"
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
