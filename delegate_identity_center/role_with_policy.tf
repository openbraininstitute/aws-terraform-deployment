resource "aws_iam_policy" "sso_admin_policy" {
  name        = "SSOAdminPolicy"
  description = "Policy to manage SSO Account Assignments and Permission Sets from delegated IAM Identity center account"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "sso:CreateAccountAssignment",
          "sso:DeleteAccountAssignment",
          "sso:ListAccountAssignments",
          "sso:ListPermissionSets",
          "sso:DescribePermissionSet",
          "sso:DescribeAccountAssignmentCreationStatus"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:sso:::permissionSet/${var.management_account_id}/*",
          "arn:aws:sso:::permissionSet/*",
          "arn:aws:sso:::account/${var.management_account_id}",
          "arn:aws:sso:::account/*",
          "arn:aws:sso:::instance/*"
        ]
      },
      {
        "Action" : [
          "iam:GetSAMLProvider"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::${var.management_account_id}:saml-provider/*"
        ]
      },
      {
        "Action" : [
          "iam:CreateRole",
          "iam:ListRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRole",
          "iam:AttachRolePolicy",
          "iam:ListAttachedRolePolicies"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "sso_admin_delegation_role" {
  name = "SSOAdminDelegationRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.delegated_idcenter_member_account_id}:user/terraform-iamidcenter-github-actions"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {}
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.delegated_idcenter_member_account_id}:root"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {}
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sso_admin_policy_attach" {
  role       = aws_iam_role.sso_admin_delegation_role.name
  policy_arn = aws_iam_policy.sso_admin_policy.arn
}
