# place to put delta.conf
resource "aws_efs_file_system" "nexus_delta_config" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-nexus-delta-config"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "sbp-poc-nexus-delta-config"
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_efs_backup_policy" "nexus_backup_policy" {
  file_system_id = aws_efs_file_system.nexus_delta_config.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_for_nexus_delta" {
  file_system_id  = aws_efs_file_system.nexus_delta_config.id
  subnet_id       = aws_subnet.nexus_delta.id
  security_groups = [aws_security_group.nexus_delta_efs.id]
}

resource "aws_route53_record" "nexus_delta_efs" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = "nexus-delta-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [aws_efs_mount_target.efs_for_nexus_delta.dns_name]
}

# TODO make more strict
resource "aws_security_group" "nexus_delta_efs" {
  name   = "nexus_delta_efs"
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  description = "Nexus app EFS filesystem"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow ingress within vpc"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow egress within vpc"
  }
  tags = {
    Application = "nexus_delta"
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_cloudwatch_log_group" "nexus_delta" {
  # TODO check if the logs can be encrypted
  name              = var.nexus_delta_app_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "nexus_delta"
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_ecs_cluster" "nexus_delta" {
  name = "nexus_delta_ecs_cluster"

  tags = {
    Application = "nexus_delta"
    SBO_Billing = "nexus_delta"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "nexus_delta_ecs_task" {
  name        = "nexus_delta_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO nexus app"

  tags = {
    Name        = "nexus_delta_secgroup"
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nexus_delta_allow_port_8080" {
  security_group_id = aws_security_group.nexus_delta_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8080 http"
  tags = {
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_vpc_security_group_egress_rule" "nexus_delta_allow_outgoing" {
  security_group_id = aws_security_group.nexus_delta_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow everything"
  tags = {
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_ecs_task_definition" "nexus_delta_ecs_definition" {
  count = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0

  family       = "nexus_delta_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory = 1024
      cpu    = 512
      command = [
        "/bin/bash",
        "-c",
        "/opt/docker/bin/delta-app -Dapp.defaults.database.password=\"$POSTGRES_PASSWORD\""
      ]
      environment = [
        {
          name  = "DELTA_PLUGINS"
          value = "/opt/docker/plugins/"
        },
        {
          name  = "DELTA_EXTERNAL_CONF"
          value = "/opt/appconf/delta.conf"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = data.aws_secretsmanager_secret_version.nexus_database_password.secret_string
        }
      ]
      networkMode = "awsvpc"
      family      = "sbonexusapp"
      essential   = true
      image       = var.nexus_delta_docker_image_url
      name        = "nexus_delta"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8080
          containerPort = 8080
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
      mountPoints = [
        {
          sourceVolume  = "efs-nexus-delta-config"
          containerPath = "/opt/appconf"
          readOnly      = true
        },
        {
          sourceVolume  = "efs-nexus-search-config"
          containerPath = "/opt/search-config"
          readOnly      = true
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.nexus_delta_app_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_delta"
        }
      }
    }
  ])

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_nexus_delta_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_nexus_delta_task_role[0].arn

  volume {
    name = "efs-nexus-delta-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_delta_config.id
      root_directory     = "/opt/appconf"
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "efs-nexus-search-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_delta_config.id
      root_directory     = "/opt/search-config"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_ecs_service" "nexus_delta_ecs_service" {
  count = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0

  name            = "nexus_delta_ecs_service"
  cluster         = aws_ecs_cluster.nexus_delta.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.nexus_delta_ecs_definition[0].arn
  desired_count   = var.nexus_delta_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  load_balancer {
    target_group_arn = aws_lb_target_group.nexus_delta.arn
    container_name   = "nexus_delta"
    container_port   = 8080
  }

  network_configuration {
    security_groups  = [aws_security_group.nexus_delta_ecs_task.id]
    subnets          = [aws_subnet.nexus_delta.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_delta,
    aws_iam_role.ecs_nexus_delta_task_execution_role, # wrong?
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_iam_role" "ecs_nexus_delta_task_execution_role" {
  count = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_delta-ecsTaskExecutionRole"

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
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_delta_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_nexus_delta_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_nexus_delta_task_role" {
  count = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_delta-ecsTaskRole"

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
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_delta_task_role_dockerhub_policy_attachment" {
  count      = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_delta_task_execution_role[0].name
  policy_arn = aws_iam_policy.dockerhub_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_delta_secrets_access_policy_attachment" {
  count      = var.nexus_delta_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_delta_task_execution_role[0].name
  policy_arn = aws_iam_policy.sbo_nexus_delta_secrets_access.arn
}
