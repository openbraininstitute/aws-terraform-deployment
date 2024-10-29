#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ml_ecs_service_consumer" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "ml-ecs-service-consumer"
  cluster_arn = local.ecs_cluster_arn

  cpu    = 512
  memory = 1024

  # Enables ECS Exec
  enable_execute_command   = true
  enable_autoscaling       = true
  autoscaling_max_capacity = 5
  autoscaling_min_capacity = 2
  desired_count            = 2

  # Container definition(s)
  container_definitions = {
    ml_consumer = {
      cpu                      = 512
      memory                   = 1024
      networkMode              = "awsvpc"
      family                   = "ml_consumer"
      essential                = true
      image                    = "${module.ml_ecr.repository_url}:${var.backend_image_tag}"
      name                     = "ml_consumer"
      entrypoint               = ["pu-consumer", "${aws_opensearch_domain.ml_opensearch.endpoint}:443", "http://${var.private_alb_dns}:3000", module.ml_sqs.queue_url, "-b", "100", "-l", 60, "-u", 3000, "--use-ssl", "-v"]
      readonly_root_filesystem = false
    }
  }
  tasks_iam_role_policies = {
    "os-policy"  = aws_iam_policy.ml_os_consumer_policy.arn
    "s3-policy"  = aws_iam_policy.ml_s3_consumer_policy.arn
    "sqs-policy" = aws_iam_policy.ml_sqs_consumer_policy.arn
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_consumer_log_policy.arn
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
  propagate_tags = "SERVICE"
}

resource "aws_iam_policy" "ml_os_consumer_policy" {
  name = "ml_os_consumer_access"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpDelete",
          "es:ESHttpHead"
        ],
        "Resource" : "arn:aws:es:${var.aws_region}:${var.account_id}:domain/${var.os_domain_name}/*"
      }
    ]
    }
  )
  tags = var.tags
}

resource "aws_iam_policy" "ml_s3_consumer_policy" {
  name = "ml_s3_consumer_access"
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
resource "aws_iam_policy" "ml_sqs_consumer_policy" {
  name = "ml_sqs_consumer_access"
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

resource "aws_iam_policy" "ml_ecs_consumer_log_policy" {
  name = "ml_ecs_consumer_logs"
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
