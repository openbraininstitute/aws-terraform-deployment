module "ml_producer_eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  # Schedules can only be created on default bus
  create_bus = false

  create_role       = true
  role_name         = "ml-ecs-producer-eventbridge"
  attach_ecs_policy = true
  ecs_target_arns   = [module.ml_ecs_task_producer.task_definition_arn]

  # Fire every five minutes
  rules = {
    ml_producer_pmc = {
      description         = "Cron for producer aimed at pmc's s3 bucket."
      schedule_expression = "cron(0 2 * * ? *)"
      state               = "ENABLED"
    }
    ml_producer_local = {
      description         = "Cron for producer aimed at our s3 bucket containing papers."
      schedule_expression = "cron(0 2 * * ? *)"
      state               = "ENABLED"
    }
  }

  # Send to a fargate ECS cluster
  targets = {
    ml_producer_pmc = [
      {
        name            = "ml_producer_pmc"
        arn             = local.ecs_cluster_arn
        attach_role_arn = true
        input = jsonencode({
          containerOverrides = [
            {
              name    = "ml_producer",
              command = ["pu-producer", "pmc-oa-opendata", "${module.ml_sqs.queue_url}", "--index", "pmc_paragraphs_v2", "--parser-name", "jats_xml", "--prefix", "oa_comm/xml/all", "oa_noncomm/xml/all", "author_manuscript/xml/all", "--file-extension", "xml", "-v"]
            }
          ]
        })

        ecs_target = {
          task_count              = 1
          task_definition_arn     = module.ml_ecs_task_producer.task_definition_arn
          enable_ecs_managed_tags = true
          propagate_tags          = "TASK_DEFINITION"
          network_configuration = {
            assign_public_ip = false
            subnets          = local.private_subnet_ids
            security_groups  = [module.ml_ecs_task_producer.security_group_id]
          }
        }
      }
    ]
    ml_producer_local = [
      {
        name            = "ml_producer_local"
        arn             = local.ecs_cluster_arn
        attach_role_arn = true
        input = jsonencode({
          containerOverrides = [
            {
              name    = "ml_producer",
              command = ["pu_producer", "ml-paper-bucket", "${module.ml_sqs.queue_url}", "--index", "pmc_paragraphs_v2", "--sign-request", "-v"]
            }
          ]
        })

        ecs_target = {
          # If a capacity_provider_strategy specified, the launch_type parameter must be omitted.
          task_count              = 1
          task_definition_arn     = module.ml_ecs_task_producer.task_definition_arn
          enable_ecs_managed_tags = true
          propagate_tags          = "TASK_DEFINITION"
          network_configuration = {
            assign_public_ip = false
            subnets          = local.private_subnet_ids
            security_groups  = [module.ml_ecs_task_producer.security_group_id]
          }
        }
      }
    ]
  }
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ml_ecs_task_producer" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                  = "ml-ecs-task-producer"
  cluster_arn           = local.ecs_cluster_arn
  task_exec_secret_arns = [var.dockerhub_credentials_arn]

  cpu    = 256
  memory = 512

  # Enables ECS Exec
  create_service         = false
  enable_execute_command = true
  enable_autoscaling     = false

  # Container definition(s)
  container_definitions = {
    ml_producer = {
      cpu         = 256
      memory      = 512
      networkMode = "awsvpc"
      family      = "ml_producer"
      essential   = true
      image       = var.backend_image_url
      name        = "ml_producer"
      repository_credentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      readonly_root_filesystem = false
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ml_producer"
          awslogs-region        = "us-east-1"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_producer"
        }
      }
    }
  }
  tasks_iam_role_policies = {
    "s3-policy"  = aws_iam_policy.ml_s3_producer_policy.arn
    "sqs-policy" = aws_iam_policy.ml_sqs_producer_policy.arn
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_producer_log_policy.arn
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags           = var.tags
  propagate_tags = "TASK_DEFINITION"

}

resource "aws_iam_policy" "ml_s3_producer_policy" {
  name = "ml_s3_producer_access"
  policy = jsonencode({
    "Version" : "2012-10-17", # tfsec:ignore:aws-iam-no-policy-wildcards
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : ["*"]
      }
    ]
    }
  )
  tags = var.tags
}
resource "aws_iam_policy" "ml_sqs_producer_policy" {
  name = "ml_sqs_producer_access"
  policy = jsonencode({
    "Version" : "2012-10-17", # tfsec:ignore:aws-iam-no-policy-wildcards
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:*"
        ],
        "Resource" : module.ml_sqs.queue_arn
      }
    ]
    }
  )
  tags = var.tags
}

resource "aws_iam_policy" "ml_ecs_producer_log_policy" {
  name = "ml_ecs_producer_logs"
  policy = jsonencode({ # tfsec:ignore:aws-iam-no-policy-wildcards
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutSubscriptionFilter",
          "logs:PutLogEvents"
        ],
        "Resource" : ["*"]
      }
    ]
    }
  )
  tags = var.tags
}
