resource "aws_grafana_workspace" "grafana-managed-workspace" {
  name                     = "cs-grafana"
  description              = "CS Grafana workspace"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["PROMETHEUS"]
  role_arn                 = aws_iam_role.assume.arn
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_iam_role_policy_attachment" "grafana_prometheus_policy_attachment" {
  role       = aws_iam_role.assume.name
  policy_arn = aws_iam_policy.grafana_prometheus_access_policy.arn
}

resource "aws_iam_role" "assume" {
  name = "grafana-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "grafana_prometheus_access_policy" {
  name = "cs-GrafanaPrometheusAccessPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ],
        "Resource" : "*"
      }
    ]
  })

  tags = {
    SBO_Billing = "keycloak"
  }
}

# Get IAM Identity Center instance
data "aws_ssoadmin_instances" "main" {}

# Get "All OBI users" group
data "aws_identitystore_group" "all_obi_users" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "All OBI users"
    }
  }
}

# Get "Infra team" group
data "aws_identitystore_group" "admin_users" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "Infra team"
    }
  }
}

# Associate role ADMIN with members of "Infra team"
resource "aws_grafana_role_association" "admin" {
  role         = "ADMIN"
  group_ids    = [data.aws_identitystore_group.admin_users.group_id]
  workspace_id = aws_grafana_workspace.grafana-managed-workspace.id
}

# Associate role VIEWER with members of "All OBI users"
resource "aws_grafana_role_association" "viewer" {
  role         = "VIEWER"
  group_ids    = [data.aws_identitystore_group.all_obi_users.group_id]
  workspace_id = aws_grafana_workspace.grafana-managed-workspace.id
}
