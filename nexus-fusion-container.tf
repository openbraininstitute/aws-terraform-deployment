resource "aws_cloudwatch_log_group" "nexus_fusion" {
  # TODO check if the logs can be encrypted
  name              = var.nexus_fusion_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "nexus_fusion"
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_ecs_cluster" "nexus_fusion" {
  name = "nexus_fusion_ecs_cluster"

  tags = {
    Application = "nexus_fusion"
    SBO_Billing = "nexus_fusion"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "nexus_fusion_ecs_task" {
  name        = "nexus_fusion_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO nexus fusion"

  tags = {
    Name        = "nexus_fusion_secgroup"
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nexus_fusion_allow_port_8000" {
  security_group_id = aws_security_group.nexus_fusion_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8000 http"
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_vpc_security_group_egress_rule" "nexus_fusion_allow_outgoing" {
  security_group_id = aws_security_group.nexus_fusion_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow everything"
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_ecs_task_definition" "nexus_fusion_ecs_definition" {
  count = var.nexus_fusion_ecs_number_of_containers > 0 ? 1 : 0

  family       = "nexus_fusion_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory = 1024
      cpu    = 512
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
          value = "bbp-nise-nexus-fusion"
        },
        {
          name  = "API_ENDPOINT"
          value = "http://${var.nexus_delta_hostname}/v1"
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
          name  = "LOGO_IMG"
          value = "https://drive.google.com/uc?id=1PDRUz6qd2rcSLX6S1Lf2oWdTNWeX8Ug9"
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
      name        = "nexus_fusion"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
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
          awslogs-group         = var.nexus_fusion_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_fusion"
        }
      }
    }
  ])

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_nexus_fusion_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_nexus_fusion_task_role[0].arn

  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_ecs_service" "nexus_fusion_ecs_service" {
  count = var.nexus_fusion_ecs_number_of_containers > 0 ? 1 : 0

  name            = "nexus_fusion_ecs_service"
  cluster         = aws_ecs_cluster.nexus_fusion.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.nexus_fusion_ecs_definition[0].arn
  desired_count   = var.nexus_fusion_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  load_balancer {
    target_group_arn = aws_lb_target_group.nexus_fusion.arn
    container_name   = "nexus_fusion"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.nexus_fusion_ecs_task.id]
    subnets          = [aws_subnet.nexus_delta.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_fusion,
    aws_iam_role.ecs_nexus_fusion_task_execution_role, # wrong?
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_iam_role" "ecs_nexus_fusion_task_execution_role" {
  count = var.nexus_fusion_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_fusion-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_fusion_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_nexus_fusion_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.nexus_fusion_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_nexus_fusion_task_role" {
  count = var.nexus_fusion_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_fusion-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_fusion_task_role_dockerhub_policy_attachment" {
  count      = var.nexus_fusion_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_fusion_task_execution_role[0].name
  policy_arn = aws_iam_policy.dockerhub_access.arn
}
