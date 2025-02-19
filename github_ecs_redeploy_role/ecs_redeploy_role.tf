resource "aws_iam_role" "github_actions_role" {
  name = "gh_redeploy_ecs_${var.ecs_service_name}_${var.repo_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_organisation}/${var.repo_name}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_update_policy" {
  name        = "gh_redeploy_ecs_${var.ecs_service_name}_${var.repo_name}"
  description = "Policy to allow updating ECS containers ${var.ecs_service_name} from repo ${var.repo_name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeClusters"
        ],
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.ecs_task_definition_name}",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:cluster/${var.ecs_cluster_name}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.ecs_update_policy.arn
}