
locals {
  fusion_cpu    = 512
  fusion_memory = 1024
}

resource "aws_ecs_task_definition" "nexus_fusion_ecs_definition" {
  family       = "${var.fusion_instance_name}_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory = local.fusion_memory
      cpu    = local.fusion_cpu
      environment = [
        {
          name  = "BASE_PATH"
          value = "/nexus/web/"
        },
        {
          name  = "HOST_NAME"
          value = "https://${var.nexus_fusion_hostname}"
        },
        {
          name  = "CLIENT_ID"
          value = "nexus-delta"
        },
        {
          name  = "API_ENDPOINT"
          value = "https://${var.nexus_delta_hostname}/v1"
        },
        {
          name  = "SERVICE_ACCOUNTS_REALM"
          value = "serviceaccounts"
        },
        {
          name  = "PLUGINS_MANIFEST_PATH"
          value = "https://bbp.epfl.ch/nexus/studio-plugins"
        },
        {
          name  = "PLUGINS_CONFIG_PATH"
          value = "/opt/nexus/public/plugins/plugins.config.json"
        },
        {
          name  = "STUDIO_VIEW"
          value = "webapps/nexus-web/nxv:studioList"
        },
        {
          name  = "GTM_CODE"
          value = "GTM-MCJDT59"
        },
        {
          name  = "SENTRY_DSN"
          value = "https://c04f7a69bcc34cf89332f8d1c3f31546@sentry.io/1845930"
        },
        {
          name  = "LOGO_LINK"
          value = "https://${var.nexus_fusion_hostname}/nexus/web/"
        },
        {
          name  = "JIRA_URL"
          value = "https://bbpteam.epfl.ch/project/issues"
        },
        {
          name  = "JIRA_RESOURCE_FIELD_NAME"
          value = "customfield_13511"
        },
        {
          name  = "JIRA_PROJECT_FIELD_NAME"
          value = "customfield_13510"
        },
        {
          name  = "JIRA_SUPPORTED_REALMS"
          value = "bbp"
        },
        {
          name  = "ANALYSIS_PLUGIN_SHOW_ON_TYPES"
          value = "DetailedCircuit,SimulationCampaignConfiguration,AnalysisReport,Report"
        },
        {
          name  = "ANALYSIS_PLUGIN_SPARQL_DATA_QUERY"
          value = "???"
        },
        {
          name  = "ANALYSIS_PLUGIN_EXCLUDE_TYPES"
          value = ""
        },
      ]
      networkMode = "awsvpc"
      family      = "sbonexusfusion"
      essential   = true
      image       = var.nexus_fusion_docker_image_url
      name        = var.fusion_instance_name
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
          name          = var.fusion_instance_name
        }
      ]
      volumesFrom = []
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.fusion_instance_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = var.fusion_instance_name
        }
      }
    }
  ])

  memory                   = local.fusion_memory
  cpu                      = local.fusion_cpu
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn
}


resource "aws_cloudwatch_log_group" "nexus_fusion" {
  name              = var.fusion_instance_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key
}
