data "aws_region" "current" {}

resource "aws_ecs_task_definition" "blazegraph_ecs_definition" {
  family       = "${var.blazegraph_instance_name}_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = var.blazegraph_memory
      networkMode = "awsvpc"
      cpu         = var.blazegraph_cpu
      family      = "blazegraph"
      portMappings = [
        {
          hostPort      = var.blazegraph_port
          containerPort = var.blazegraph_port
          protocol      = "tcp"
          name          = var.blazegraph_instance_name
        }
      ]
      essential = true
      name      = "blazegraph"
      image     = var.blazegraph_docker_image_url
      environment = [
        {
          name  = "JAVA_OPTS"
          value = "-Dlog4j.configuration=/var/lib/blazegraph/config/log4j.properties -DjettyXml=/var/lib/blazegraph/config/jetty.xml -Djava.awt.headless=true ${var.blazegraph_java_opts}"
        },
        {
          name  = "JETTY_START_TIMEOUT"
          value = "120"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.blazegraph_app_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "blazegraph_app"
        }
      }
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      mountPoints = [
        {
          sourceVolume  = "efs-blazegraph-config"
          containerPath = "/var/lib/blazegraph/config"
          readOnly      = true
        },
        {
          sourceVolume  = "efs-blazegraph-data"
          containerPath = "/var/lib/blazegraph/data"
          readOnly      = false
        }
      ]
      dependsOn = [
        {
          containerName = "blazegraph-config"
          condition     = "COMPLETE"
        }
      ]
    },
    {
      name      = "blazegraph-config"
      image     = "bash"
      essential = false
      command = [
        "sh",
        "-c",
        <<-EOT
          echo $JETTY_CONFIG  | base64 -d - | tee /var/lib/blazegraph/config/jetty.xml && \
          echo $LOG4J_CONFIG  | base64 -d - | tee /var/lib/blazegraph/config/log4j.properties
        EOT
      ],
      environment = [
        {
          name  = "JETTY_CONFIG"
          value = base64encode(file("${path.module}/jetty.xml"))
        },
        {
          name  = "LOG4J_CONFIG"
          value = base64encode(file("${path.module}/log4j.properties"))
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "efs-blazegraph-config"
          containerPath = "/var/lib/blazegraph/config"
        }
      ]
    }
  ])

  cpu                      = var.blazegraph_cpu
  memory                   = var.blazegraph_memory
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn

  volume {
    name = "efs-blazegraph-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blazegraph.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blazegraph.id
        iam             = "DISABLED"
      }
    }
  }

  volume {
    name = "efs-blazegraph-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blazegraph.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blazegraph.id
        iam             = "DISABLED"
      }
    }
  }
}
