# Additional policies for users

# IAM Identity Center ARN
# Old name: IAM Single Sign-on
# Often confused with 'IAM', which is a separate thing
variable "aws_iam_identity_center_arn" {
  default     = "arn:aws:sso:::instance/ssoins-7223effe437e4dbf"
  type        = string
  description = "ARN of the IAM Identity Center"
  sensitive   = false
}


# example full policy
#resource "aws_iam_policy" "sbo_ec2_serial_console_access" {
#    name        = "sbo_ec2_serial_console_access"
#    description = "access to the serial console of EC2 machines"
#
#    policy = jsonencode({
#        Version = "2012-10-17"
#        Statement = [
#            {
#                Effect = "Allow"
#                Action = [
#                    "ec2:GetSerialConsoleAccessStatus",
#                    "ec2:EnableSerialConsoleAccess",
#                    "ec2:DisableSerialConsoleAccess",
#                ]
#                Resource = "*"
#            }
#        ]
#    })
#
#    tags = {
#        SBO_Billing = "common"
#    }
#}

# doesn't work: always validation error
/*
resource "aws_identitystore_group" "sbo_hpc_users" {
    display_name      = "hpcusers"
    #description       = "HPC users with read only access and additional rights such as access to serial consoles"
    identity_store_id = var.aws_iam_identity_center_arn

}

resource "aws_ssoadmin_account_assignment" "sbo_hpc_users" {
    instance_arn       = var.aws_iam_identity_center_arn
    permission_set_arn = aws_ssoadmin_permission_set.readonly_with_additional_hpc_rights.arn
    principal_id       = aws_identitystore_group.sbo_hpc_users.group_id
    principal_type     = "GROUP"
    target_id          = "671250183987"
    target_type        = "AWS_ACCOUNT"
}
*/

resource "aws_ssoadmin_permission_set" "readonly_with_additional_hpc_rights" {
  name         = "ReadOnlyWithAdditionalHPCRights"
  description  = "Read only access and also HPC extras such as serial console access"
  instance_arn = var.aws_iam_identity_center_arn

  #relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#"
  session_duration = "PT2H"

  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_with_additional_hpc_rights" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
      jsondecode(local.sbo_ec2_serial_console_access_policy_statement),
    ]
  })

  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_with_additional_hpc_rights.arn
}

resource "aws_ssoadmin_permission_set" "readonly_with_additional_s3_rights" {
  name         = "ReadOnlyWithAdditionalS3Rights"
  description  = "Read only access but with full S3 access"
  instance_arn = var.aws_iam_identity_center_arn

  #relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#"
  session_duration = "PT2H"

  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_with_additional_s3_rights" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
      jsondecode(local.s3_access_policy_statement),
    ]
  })

  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_with_additional_s3_rights.arn
}

resource "aws_ssoadmin_permission_set" "readonly_with_additional_dashboard_rights" {
  name         = "ReadOnlyWithDashboardRights"
  description  = "Read only access but with full dashboard access"
  instance_arn = var.aws_iam_identity_center_arn

  #relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#"
  session_duration = "PT2H"

  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_with_additional_dashboard_rights" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
      jsondecode(local.dashboard_access_policy_statement),
    ]
  })

  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_with_additional_dashboard_rights.arn
}


resource "aws_ssoadmin_permission_set" "readonly_with_additional_billing_rights" {
  name         = "FullBillingAndPaymentsAccess"
  description  = "Read only access for most but full access for billing, payments, budgets, ..."
  instance_arn = var.aws_iam_identity_center_arn

  #relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#"
  session_duration = "PT2H"

  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_with_additional_billing_rights" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
      jsondecode(local.sbo_billing_payment_support_full_access_policy_statement),
    ]
  })

  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_with_additional_billing_rights.arn
}

resource "aws_ssoadmin_permission_set" "readonly_with_additional_ecs_rights" {
  name         = "FullECSContainersAccess"
  description  = "Read only access for most but full access to ECS so containers can be managed"
  instance_arn = var.aws_iam_identity_center_arn

  #relay_state      = "https://s3.console.aws.amazon.com/s3/home?region=us-east-1#"
  session_duration = "PT2H"

  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_with_additional_ecs_rights" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.readonly_access_policy_statement_part1),
      jsondecode(local.readonly_access_policy_statement_part2),
      jsondecode(local.sbo_ecs_full_access_policy_statement),
      jsondecode(local.sbo_ecr_allow_pull_push_policy_statement),
      jsondecode(local.pass_role_to_ecs_policy_statement),
    ]
  })

  instance_arn       = var.aws_iam_identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_with_additional_ecs_rights.arn
}

locals {
  dashboard_access_policy_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "cloudwatch:PutDashboard",
      "cloudwatch:DeleteDashboards",
    ]
    Resource = "*"
  })

  sbo_ec2_serial_console_access_policy_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "ec2:GetSerialConsoleAccessStatus",
      "ec2:EnableSerialConsoleAccess",
      "ec2:DisableSerialConsoleAccess",
      "ec2-instance-connect:SendSerialConsoleSSHPublicKey",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
    ]
    Resource = "*"
  })

  sbo_ecs_full_access_policy_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "ecs:Update*",
      "ecs:Submit*",
      "ecs:List*",
      "ecs:Get*",
      "ecs:Describe*",
      "ecs:Deregister*",
      "ecs:DeleteT*",
      "ecs:DeleteAttributes",
      "ecs:ExecuteCommand",
      "ecs:RegisterTaskDefinition",
      "ecs:RunTask",
      "Ecs:StartTask",
      "ecs:StopTask",
      "ssm:StartSession",
      "ecs:TagResource"
    ]
    Resource = "*"
  })

  # from https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html#IAM_within_account
  sbo_ecr_allow_pull_push_policy_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    Resource = "*"
  })

  pass_role_to_ecs_policy_statement = jsonencode(
    {
      "Action" : "iam:PassRole",
      "Effect" : "Allow",
      "Resource" : [
        "*"
      ],
      "Condition" : {
        "StringLike" : {
          "iam:PassedToService" : "ecs-tasks.amazonaws.com"
        }
      }
    }
  )

  s3_access_policy_statement = jsonencode({
    Action = [
      "s3:*",
      "s3express:*",
    ]
    Resource = "*",
    Effect   = "Allow"
  })

  sbo_billing_payment_support_full_access_policy_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "support:*",
      "consolidatedbilling:*",
      "account:*",
      "tax:*",
      "invoicing:*",
      "payments:*",
      "servicequotas:*",
      "ce:*",
      "billing:*",
      "billingconductor:*",
      "budgets:*",
    ]
    Resource = "*"
  })
  /* todo support
            "support:DescribeAttachment",
            "support:DescribeCases",
            "support:DescribeCommunications",
            "support:DescribeServices",
            "support:DescribeSeverityLevels",
            "support:DescribeTrustedAdvisorCheckRefreshStatuses",
            "support:DescribeTrustedAdvisorCheckResult",
            "support:DescribeTrustedAdvisorChecks",
            "support:DescribeTrustedAdvisorCheckSummaries",
            "supportplans:GetSupportPlan",
            "supportplans:GetSupportPlanUpdateStatus",
            */
  readonly_access_policy_statement_part1 = jsonencode({
    Effect = "Allow"
    Action = [
      #"a4b:Get*",
      #"a4b:List*",
      #"a4b:Search*",
      #"access-analyzer:GetAccessPreview",
      #"access-analyzer:GetAnalyzedResource",
      #"access-analyzer:GetAnalyzer",
      #"access-analyzer:GetArchiveRule",
      #"access-analyzer:GetFinding",
      #"access-analyzer:GetGeneratedPolicy",
      #"access-analyzer:ListAccessPreviewFindings",
      #"access-analyzer:ListAccessPreviews",
      #"access-analyzer:ListAnalyzedResources",
      #"access-analyzer:ListAnalyzers",
      #"access-analyzer:ListArchiveRules",
      #"access-analyzer:ListFindings",
      #"access-analyzer:ListPolicyGenerations",
      #"access-analyzer:ListTagsForResource",
      #"access-analyzer:ValidatePolicy",
      "account:ListRegions",
      "apigateway:GET",
      "appconfig:GetApplication",
      "appconfig:GetConfiguration",
      "appconfig:GetConfigurationProfile",
      "appconfig:GetDeployment",
      "appconfig:GetDeploymentStrategy",
      "appconfig:GetEnvironment",
      "appconfig:GetHostedConfigurationVersion",
      "appconfig:ListApplications",
      "appconfig:ListConfigurationProfiles",
      "appconfig:ListDeployments",
      "appconfig:ListDeploymentStrategies",
      "appconfig:ListEnvironments",
      "appconfig:ListHostedConfigurationVersions",
      "appconfig:ListTagsForResource",
      "application-autoscaling:Describe*",
      "applicationinsights:Describe*",
      "applicationinsights:List*",
      #"appmesh:Describe*",
      #"appmesh:List*",
      #"appstream:Describe*",
      #"appstream:List*",
      #"appsync:Get*",
      #"appsync:List*",
      "artifact:GetReport",
      "artifact:GetReportMetadata",
      "artifact:GetTermForReport",
      "artifact:ListReports",
      #"autoscaling-plans:Describe*",
      #"autoscaling-plans:GetScalingPlanResourceForecastData",
      #"autoscaling:Describe*",
      #"autoscaling:GetPredictiveScalingForecast",
      "aws-portal:View*",
      "backup-gateway:ListGateways",
      "backup-gateway:ListHypervisors",
      "backup-gateway:ListTagsForResource",
      "backup-gateway:ListVirtualMachines",
      "backup:Describe*",
      "backup:Get*",
      "backup:List*",
      "batch:Describe*",
      "batch:List*",
      #"cassandra:Select",
      #"cloudformation:Describe*",
      #"cloudformation:Detect*",
      #"cloudformation:Estimate*",
      #"cloudformation:Get*",
      #"cloudformation:List*",
      #"cloudtrail:Describe*",
      #"cloudtrail:Get*",
      #"cloudtrail:List*",
      #"cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      #"codebuild:BatchGet*",
      #"codebuild:DescribeCodeCoverages",
      #"codebuild:DescribeTestCases",
      #"codebuild:List*",
      #"codedeploy:BatchGet*",
      #"codedeploy:Get*",
      #"codedeploy:List*",
      #"compute-optimizer:DescribeRecommendationExportJobs",
      #"compute-optimizer:GetAutoScalingGroupRecommendations",
      #"compute-optimizer:GetEBSVolumeRecommendations",
      #"compute-optimizer:GetEC2InstanceRecommendations",
      #"compute-optimizer:GetEC2RecommendationProjectedMetrics",
      #"compute-optimizer:GetECSServiceRecommendationProjectedMetrics",
      #"compute-optimizer:GetECSServiceRecommendations",
      #"compute-optimizer:GetEffectiveRecommendationPreferences",
      #"compute-optimizer:GetEnrollmentStatus",
      #"compute-optimizer:GetEnrollmentStatusesForOrganization",
      #"compute-optimizer:GetLambdaFunctionRecommendations",
      #"compute-optimizer:GetRecommendationPreferences",
      #"compute-optimizer:GetRecommendationSummaries",
      "config:BatchGetAggregateResourceConfig",
      "config:BatchGetResourceConfig",
      "config:Deliver*",
      "config:Describe*",
      "config:Get*",
      "config:List*",
      "config:SelectAggregateResourceConfig",
      "config:SelectResourceConfig",
      "consoleapp:GetDeviceIdentity",
      "consoleapp:ListDeviceIdentities",
      "customer-verification:GetCustomerVerificationDetails",
      "customer-verification:GetCustomerVerificationEligibility",
      "dataexchange:Get*",
      "dataexchange:List*",
      "datasync:Describe*",
      "datasync:List*",
      #"detective:BatchGetGraphMemberDatasources",
      #"detective:BatchGetMembershipDatasources",
      #"detective:Get*",
      #"detective:List*",
      #"detective:SearchGraph",
      #"directconnect:Describe*",
      "discovery:Describe*",
      "discovery:Get*",
      "discovery:List*",
      "dlm:Get*",
      "dms:Describe*",
      "dms:List*",
      "dms:Test*",
      "ds:Check*",
      #"ds:Describe*",
      #"ds:Get*",
      #"ds:List*",
      #"ds:Verify*",
      #"dynamodb:BatchGet*",
      #"dynamodb:Describe*",
      #"dynamodb:Get*",
      #"dynamodb:List*",
      #"dynamodb:PartiQLSelect",
      #"dynamodb:Query",
      #"dynamodb:Scan",
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:ListImagesInRecycleBin",
      "ec2:ListSnapshotsInRecycleBin",
      "ec2:SearchLocalGatewayRoutes",
      "ec2:SearchTransitGatewayRoutes",
      "ec2messages:Get*",
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:DescribeImages",
      "ecr-public:DescribeImageTags",
      "ecr-public:DescribeRegistries",
      "ecr-public:DescribeRepositories",
      "ecr-public:GetAuthorizationToken",
      "ecr-public:GetRegistryCatalogData",
      "ecr-public:GetRepositoryCatalogData",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:ListTagsForResource",
      "ecr:BatchCheck*",
      "ecr:BatchGet*",
      "ecr:Describe*",
      "ecr:Get*",
      "ecr:List*",
      "ecs:Describe*",
      "ecs:List*",
      "eks:Describe*",
      "eks:List*",
      #"elastic-inference:DescribeAcceleratorOfferings",
      #"elastic-inference:DescribeAccelerators",
      #"elastic-inference:DescribeAcceleratorTypes",
      #"elastic-inference:ListTagsForResource",
      #"elasticache:Describe*",
      #"elasticache:List*",
      #"elasticbeanstalk:Check*",
      #"elasticbeanstalk:Describe*",
      #"elasticbeanstalk:List*",
      #"elasticbeanstalk:Request*",
      #"elasticbeanstalk:Retrieve*",
      #"elasticbeanstalk:Validate*",
      #"elasticfilesystem:Describe*",
      #"elasticfilesystem:ListTagsForResource",
      #"elasticloadbalancing:Describe*",
      #"elemental-appliances-software:Get*",
      #"elemental-appliances-software:List*",
      "es:Describe*",
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:Get*",
      "es:List*",
      "events:Describe*",
      "events:List*",
      "events:Test*",
      #"firehose:Describe*",
      #"firehose:List*",
      #"freetier:GetFreeTierAlertPreference",
      #"freetier:GetFreeTierUsage",
      #"fsx:Describe*",
      #"fsx:List*",
      "glacier:Describe*",
      "glacier:Get*",
      "glacier:List*",
      "health:Describe*",
      "iam:Generate*",
      "iam:Get*",
      "iam:List*",
      "iam:Simulate*",
    ]
    Resource = "*"
  })

  identity_management_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "cognito-identity:Describe*",
      "cognito-identity:GetCredentialsForIdentity",
      "cognito-identity:GetIdentityPoolRoles",
      "cognito-identity:GetOpenIdToken",
      "cognito-identity:GetOpenIdTokenForDeveloperIdentity",
      "cognito-identity:List*",
      "cognito-identity:Lookup*",
      "cognito-idp:AdminGet*",
      "cognito-idp:AdminList*",
      "cognito-idp:Describe*",
      "cognito-idp:Get*",
      "cognito-idp:List*",
      "cognito-sync:Describe*",
      "cognito-sync:Get*",
      "cognito-sync:List*",
      "cognito-sync:QueryRecords",

      "identity-sync:GetSyncProfile",
      "identity-sync:GetSyncTarget",
      "identity-sync:ListSyncFilters",
      "identitystore-auth:BatchGetSession",
      "identitystore-auth:ListSessions",
      "identitystore:DescribeGroup",
      "identitystore:DescribeGroupMembership",
      "identitystore:DescribeUser",
      "identitystore:GetGroupId",
      "identitystore:GetGroupMembershipId",
      "identitystore:GetUserId",
      "identitystore:IsMemberInGroups",
      "identitystore:ListGroupMemberships",
      "identitystore:ListGroupMembershipsForMember",
      "identitystore:ListGroups",
      "identitystore:ListUsers",
      "sso-directory:Describe*",
      "sso-directory:List*",
      "sso-directory:Search*",
      "sso:Describe*",
      "sso:Get*",
      "sso:List*",
      "sso:Search*",
    ]
    Resource = "*"
  })

  billing_related_statement = jsonencode({
    Effect = "Allow"
    Action = [
      "account:GetAccountInformation",
      "account:GetAlternateContact",
      "account:GetChallengeQuestions",
      "account:GetContactInformation",
      "account:GetRegionOptStatus",
      "consolidatedbilling:GetAccountBillingRole",
      "consolidatedbilling:ListLinkedAccounts",

      "tax:GetExemptions",
      "tax:GetExemptions",
      "tax:GetTaxInheritance",
      "tax:GetTaxInterview",
      "tax:GetTaxRegistration",
      "tax:GetTaxRegistrationDocument",
      "tax:ListTaxRegistrations",
      "invoicing:GetInvoiceEmailDeliveryPreferences",
      "invoicing:GetInvoicePDF",
      "invoicing:ListInvoiceSummaries",
      "payments:GetPaymentInstrument",
      "payments:GetPaymentStatus",
      "payments:ListPaymentPreferences",
      "servicequotas:GetAssociationForServiceQuotaTemplate",
      "servicequotas:GetAWSDefaultServiceQuota",
      "servicequotas:GetRequestedServiceQuotaChange",
      "servicequotas:GetServiceQuota",
      "servicequotas:GetServiceQuotaIncreaseRequestFromTemplate",
      "servicequotas:ListAWSDefaultServiceQuotas",
      "servicequotas:ListRequestedServiceQuotaChangeHistory",
      "servicequotas:ListRequestedServiceQuotaChangeHistoryByQuota",
      "servicequotas:ListServiceQuotaIncreaseRequestsInTemplate",
      "servicequotas:ListServiceQuotas",
      "servicequotas:ListServices",
      "ce:DescribeCostCategoryDefinition",
      "ce:DescribeNotificationSubscription",
      "ce:DescribeReport",
      "ce:GetAnomalies",
      "ce:GetAnomalyMonitors",
      "ce:GetAnomalySubscriptions",
      "ce:GetCostAndUsage",
      "ce:GetCostAndUsageWithResources",
      "ce:GetCostCategories",
      "ce:GetCostForecast",
      "ce:GetDimensionValues",
      "ce:GetPreferences",
      "ce:GetReservationCoverage",
      "ce:GetReservationPurchaseRecommendation",
      "ce:GetReservationUtilization",
      "ce:GetRightsizingRecommendation",
      "ce:GetSavingsPlansCoverage",
      "ce:GetSavingsPlansPurchaseRecommendation",
      "ce:GetSavingsPlansUtilization",
      "ce:GetSavingsPlansUtilizationDetails",
      "ce:GetTags",
      "ce:GetUsageForecast",
      "ce:ListCostAllocationTags",
      "ce:ListCostCategoryDefinitions",
      "ce:ListSavingsPlansPurchaseRecommendationGeneration",
      "ce:ListTagsForResource",
      "billing:GetBillingData",
      "billing:GetBillingDetails",
      "billing:GetBillingNotifications",
      "billing:GetBillingPreferences",
      "billing:GetContractInformation",
      "billing:GetCredits",
      "billing:GetIAMAccessPreference",
      "billing:GetSellerOfRecord",
      "billing:ListBillingViews",
      "billingconductor:ListAccountAssociations",
      "billingconductor:ListBillingGroupCostReports",
      "billingconductor:ListBillingGroups",
      "billingconductor:ListCustomLineItems",
      "billingconductor:ListCustomLineItemVersions",
      "billingconductor:ListPricingPlans",
      "billingconductor:ListPricingPlansAssociatedWithPricingRule",
      "billingconductor:ListPricingRules",
      "billingconductor:ListPricingRulesAssociatedToPricingPlan",
      "billingconductor:ListResourcesAssociatedToCustomLineItem",
      "billingconductor:ListTagsForResource",
      "budgets:Describe*",
      "budgets:View*",

    ]
    Resource = "*"
  })

  readonly_access_policy_statement_part2 = jsonencode({
    Effect = "Allow"
    Action = [
      "imagebuilder:Get*",
      "imagebuilder:List*",
      "importexport:Get*",
      "importexport:List*",
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "lambda:Get*",
      "lambda:List*",
      "license-manager:Get*",
      "license-manager:List*",

      "logs:Describe*",
      "logs:FilterLogEvents",
      "logs:Get*",
      "logs:ListTagsForResource",
      "logs:ListTagsLogGroup",
      "logs:StartLiveTail",
      "logs:StartQuery",
      "logs:StopLiveTail",
      "logs:StopQuery",
      "logs:TestMetricFilter",
      "mq:Describe*",
      "mq:List*",
      "notifications-contacts:GetEmailContact",
      "notifications-contacts:ListEmailContacts",
      "notifications-contacts:ListTagsForResource",
      "notifications:GetEventRule",
      "notifications:GetNotificationConfiguration",
      "notifications:GetNotificationEvent",
      "notifications:ListChannels",
      "notifications:ListEventRules",
      "notifications:ListNotificationConfigurations",
      "notifications:ListNotificationEvents",
      "notifications:ListNotificationHubs",
      "notifications:ListTagsForResource",
      "oam:GetLink",
      "oam:GetSink",
      "oam:GetSinkPolicy",
      "oam:ListAttachedLinks",
      "oam:ListLinks",
      "oam:ListSinks",
      "omics:Get*",
      "omics:List*",
      "organizations:Describe*",
      "organizations:List*",
      "osis:GetPipeline",
      "osis:GetPipelineBlueprint",
      "osis:GetPipelineChangeProgress",
      "osis:ListPipelineBlueprints",
      "osis:ListPipelines",
      "osis:ListTagsForResource",
      "personalize:Describe*",
      "personalize:Get*",
      "personalize:List*",
      "pi:DescribeDimensionKeys",
      "pi:GetDimensionKeyDetails",
      "pi:GetResourceMetadata",
      "pi:GetResourceMetrics",
      "pi:ListAvailableResourceDimensions",
      "pi:ListAvailableResourceMetrics",
      "pipes:DescribePipe",
      "pipes:ListPipes",
      "pipes:ListTagsForResource",
      "purchase-orders:GetPurchaseOrder",
      "purchase-orders:ListPurchaseOrderInvoices",
      "purchase-orders:ListPurchaseOrders",
      "purchase-orders:ViewPurchaseOrders",
      "ram:Get*",
      "ram:List*",
      "rbin:GetRule",
      "rbin:ListRules",
      "rbin:ListTagsForResource",
      "rds:Describe*",
      "rds:Download*",
      "rds:List*",
      "redshift:Describe*",
      "redshift:GetReservedNodeExchangeOfferings",
      "redshift:View*",
      "resource-explorer-2:BatchGetView",
      "resource-explorer-2:GetDefaultView",
      "resource-explorer-2:GetIndex",
      "resource-explorer-2:GetView",
      "resource-explorer-2:ListIndexes",
      "resource-explorer-2:ListSupportedResourceTypes",
      "resource-explorer-2:ListTagsForResource",
      "resource-explorer-2:ListViews",
      "resource-explorer-2:Search",
      "resource-groups:Get*",
      "resource-groups:List*",
      "resource-groups:Search*",
      "route53-recovery-cluster:Get*",
      "route53-recovery-cluster:ListRoutingControls",
      "route53-recovery-control-config:Describe*",
      "route53-recovery-control-config:List*",
      "route53-recovery-readiness:Get*",
      "route53-recovery-readiness:List*",
      "route53:Get*",
      "route53:List*",
      "route53:Test*",
      "route53domains:Check*",
      "route53domains:Get*",
      "route53domains:List*",
      "route53domains:View*",
      "route53resolver:Get*",
      "route53resolver:List*",
      "rum:GetAppMonitor",
      "rum:GetAppMonitorData",
      "rum:ListAppMonitors",
      "s3-object-lambda:GetObject",
      "s3-object-lambda:GetObjectAcl",
      "s3-object-lambda:GetObjectLegalHold",
      "s3-object-lambda:GetObjectRetention",
      "s3-object-lambda:GetObjectTagging",
      "s3-object-lambda:GetObjectVersion",
      "s3-object-lambda:GetObjectVersionAcl",
      "s3-object-lambda:GetObjectVersionTagging",
      "s3-object-lambda:ListBucket",
      "s3-object-lambda:ListBucketMultipartUploads",
      "s3-object-lambda:ListBucketVersions",
      "s3-object-lambda:ListMultipartUploadParts",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:List*",
      "savingsplans:DescribeSavingsPlanRates",
      "savingsplans:DescribeSavingsPlans",
      "savingsplans:DescribeSavingsPlansOfferingRates",
      "savingsplans:DescribeSavingsPlansOfferings",
      "savingsplans:ListTagsForResource",
      "scheduler:GetSchedule",
      "scheduler:GetScheduleGroup",
      "scheduler:ListScheduleGroups",
      "scheduler:ListSchedules",
      "scheduler:ListTagsForResource",
      "schemas:Describe*",
      "schemas:Get*",
      "schemas:List*",
      "schemas:Search*",
      "sdb:Get*",
      "sdb:List*",
      "sdb:Select*",
      "secretsmanager:Describe*",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:List*",
      "serverlessrepo:Get*",
      "serverlessrepo:List*",
      "serverlessrepo:SearchApplications",
      "servicecatalog:Describe*",
      "servicecatalog:GetApplication",
      "servicecatalog:GetAttributeGroup",
      "servicecatalog:List*",
      "servicecatalog:Scan*",
      "servicecatalog:Search*",
      "servicediscovery:Get*",
      "servicediscovery:List*",

      "snowball:Describe*",
      "snowball:Get*",
      "snowball:List*",
      "storagegateway:Describe*",
      "storagegateway:List*",
      "sts:GetAccessKeyInfo",
      "sts:GetCallerIdentity",
      "sts:GetSessionToken",
      "tag:DescribeReportCreation",
      "tag:Get*",
    ]
    Resource = "*"
  })
}
