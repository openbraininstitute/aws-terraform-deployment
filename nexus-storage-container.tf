resource "aws_cloudwatch_log_group" "nexus_storage" {
  name              = var.nexus_storage_service_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "nexus_storage"
    SBO_Billing = "nexus_storage"
  }
}

resource "aws_ecs_cluster" "nexus_storage" {
  name = "nexus_storage_ecs_cluster"

  tags = {
    Application = "nexus_storage"
    SBO_Billing = "nexus_storage"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_security_group" "nexus_storage_ecs_task" {
  name        = "nexus_storage_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO nexus storage service"

  tags = {
    Name        = "nexus_storage_secgroup"
    SBO_Billing = "nexus_storage"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nexus_storage_allow_port_8080" {
  security_group_id = aws_security_group.nexus_storage_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8081
  to_port     = 8081
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8081 http"
  tags = {
    SBO_Billing = "nexus_storage"
  }
}

// TODO: once we have S3 bucket info we should only need egress to the mounted volume using whatever protocol is supported
resource "aws_vpc_security_group_egress_rule" "nexus_storage_allow_outgoing" {
  security_group_id = aws_security_group.nexus_storage_ecs_task.id
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"
  tags = {
    SBO_Billing = "nexus_storage"
  }
}

resource "aws_ecs_task_definition" "nexus_storage_ecs_definition" {
  count = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0

  family       = "nexus_storage_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory = 8192
      cpu    = 2048
      # TODO only overriding properties currently present in storage.conf on the parallel cluster.
      # The rest are bundled in the jar from various files - maybe it should all be in one place?
      command = [
        "/bin/bash",
        "-c",
        "/opt/docker/bin/storage",
        "-Dapp.instance.interface=0.0.0.0",
        "-Dakka.http.server.parsing.max-content-length=100g",
        "-Dakka.http.client.parsing.max-content-length=100g",
        "-Dakka.http.server.request-timeout=5 minutes",
        "-Dapp.http.port=8081",
        "-Dapp.storage.root-volume=/does/not/exist", # TODO depends on how we mount the volume
        "-Dapp.storage.extra-prefixes.0=",           # TODO empty for now, depends on how we mount the volume
        "-Dapp.storage.protected-directory=nexus",
        "-Dapp.storage.fixer-enabled=false", # TODO depends on how we mount the volume
        "-Dapp.storage.fixer-command.0=null",
        "-Dapp.authorization.type=anonymous"
        # TODO reinstate once parsing keys from properties is fixed
        # "-Dapp.authorization.issuer=https://sboauth.epfl.ch/auth/realms/SBO",
        # "-Dapp.authorization.subject=service-account-nexus-delta",
        # "-Dapp.authorization.keys.0.kid=UTJGGczwZ76W83wzM5k6LdnnVUuGEGJ2DTxTjyQD9-Y",
        # "-Dapp.authorization.keys.0.kty=RSA",
        # "-Dapp.authorization.keys.0.alg=RSA-OAEP",
        # "-Dapp.authorization.keys.0.use=enc",
        # "-Dapp.authorization.keys.0.n=ueE-G8QrHYleaPY6GB02eFU0B7SEb5hp3j4skFNw6VREaqJT2Tf5iFQE6ZeVwoYpT01bb3W-hg2TMnB_9mqMieWk51JdgIgPdNfR6jTGY233vmIMj1fEHdF5yzzJWlBYzj0vXmdOXkWmoTerQWuZeooJYvAhk7u_nW1KyDQAU99CSLBynlR_EOL13ERoGjipY0Mpew0cMUsntJgjTuRPjNR6-zdQfSvT3Fb_tqs1xPnWc_o8JCgRAJIxi4MauHto-dPNbArniGb65Rwsnw_lAD63ZZRDqXxTWsixqOX18SbcuCteYJ3FyZdHjkV8QmuBwrSarVu0jzfH-o_pcwA0vw",
        # "-Dapp.authorization.keys.0.e=AQAB",
        # "-Dapp.authorization.keys.0.x5c.0=MIIClTCCAX0CBgGJbf5HzDANBgkqhkiG9w0BAQsFADAOMQwwCgYDVQQDDANTQk8wHhcNMjMwNzE5MTE1MDI4WhcNMzMwNzE5MTE1MjA4WjAOMQwwCgYDVQQDDANTQk8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC54T4bxCsdiV5o9joYHTZ4VTQHtIRvmGnePiyQU3DpVERqolPZN/mIVATpl5XChilPTVtvdb6GDZMycH/2aoyJ5aTnUl2AiA9019HqNMZjbfe+YgyPV8Qd0XnLPMlaUFjOPS9eZ05eRaahN6tBa5l6igli8CGTu7+dbUrINABT30JIsHKeVH8Q4vXcRGgaOKljQyl7DRwxSye0mCNO5E+M1Hr7N1B9K9PcVv+2qzXE+dZz+jwkKBEAkjGLgxq4e2j5081sCueIZvrlHCyfD+UAPrdllEOpfFNayLGo5fXxJty4K15gncXJl0eORXxCa4HCtJqtW7SPN8f6j+lzADS/AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAEwGjfiypbacK6qGuOJv/ctZRQloCcfQqQVYjk2OVJtmi6P2MVKV1JT3CvGPhpT2qV31rGUvxgdYWPkyO11Tl7Kv1YuYo3kuIzYUsoFSrP4YkXH08SYZZmn7igorkV6EPQq+Wuxgkf7VxT8DsEw6hvN7m0PX6UCTOJu5QLSLJNZzChqVUbH/FTKYj529NDdUqyk8cJCy8vYVPOrgTEXTNFdYilO1pUcgnKYVZ/A6swLOVpA0nUtNaNTYLEOE/yPMSDCHpN5x9f7a2FmKnLhb7Hof610X37uehAcrAvKbNlFnyVe+5Wf4T9Hr6OFSGObIf4eBIs3z57aUzJZrpSLwhsg=",
        # "-Dapp.authorization.keys.0.x5t=O_JGgGoSjSwv1JDr8TRb9YlhMIY",
        # "-Dapp.authorization.keys.0.x5t#S256=8sxasFIoAqkNYIK1rrXszvyiE2MNkxDU9qMposUHbBM",
        # "-Dapp.authorization.keys.1.kid=YU12LJ24mlDTbyDeYx2he9FD3nWdZPRWjbIUikhhqQU",
        # "-Dapp.authorization.keys.1.kty=RSA",
        # "-Dapp.authorization.keys.1.alg=RS256",
        # "-Dapp.authorization.keys.1.use=sig",
        # "-Dapp.authorization.keys.1.n=qQcAjNPjrjZc1mRW4nltsGNhsKRq4W0SHBXPM8luTRLOnOrNnB36yZIlpXLIbeuDqAE-fwVHmejv9RtsDXosOxll37wgMj5mE4sblXqeeGy3Co0tJrbhnFnNkX2fhIWEJZhqZW1J_tJ0HLSmBOAS7G_JiVsKd31vUjF9WjjlNIrNHjGN8g3N6I9U6oypkraaqsAxFDZT4D3y3nv8e_eCrH0BsW3Qtmo46BnBrtaY1IPW_tdLtMNq3m3yuAKvfrJVpLj2OU-I5dRR3-2KMb8uRIILiqnmBCq3NwkwsAnO0Fs26eAasqii-meTbkxcvMlly5qkcJBdFVyImvDk0FzFxw",
        # "-Dapp.authorization.keys.1.e=AQAB",
        # "-Dapp.authorization.keys.1.x5c.0=MIIClTCCAX0CBgGJbf5GMTANBgkqhkiG9w0BAQsFADAOMQwwCgYDVQQDDANTQk8wHhcNMjMwNzE5MTE1MDI3WhcNMzMwNzE5MTE1MjA3WjAOMQwwCgYDVQQDDANTQk8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpBwCM0+OuNlzWZFbieW2wY2GwpGrhbRIcFc8zyW5NEs6c6s2cHfrJkiWlcsht64OoAT5/BUeZ6O/1G2wNeiw7GWXfvCAyPmYTixuVep54bLcKjS0mtuGcWc2RfZ+EhYQlmGplbUn+0nQctKYE4BLsb8mJWwp3fW9SMX1aOOU0is0eMY3yDc3oj1TqjKmStpqqwDEUNlPgPfLee/x794KsfQGxbdC2ajjoGcGu1pjUg9b+10u0w2rebfK4Aq9+slWkuPY5T4jl1FHf7Yoxvy5EgguKqeYEKrc3CTCwCc7QWzbp4BqyqKL6Z5NuTFy8yWXLmqRwkF0VXIia8OTQXMXHAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAImrsOnZb63wDc5aeeKmNTDUR9NK99nl9jx6H1OjbHiYLR9FngEAZeESkA5zhesi7osxd2Z7GefP7vrNMguu02kY1CJEgb+Fz/Wsg4eOAzU2qAtvTZniagEgHWTrlHufugTrsxgWst63lUB+ftmFE5YtVVso9b5FIbvXIlM1caVa1GSEsuxFFLYMUEg06zR0353j9zoP0xyjxQgQsXl9nlsSuQUJT9jK7+rIdwhA8+L0Rj8jhw+QyG0VF2LMyqCTMZV8uxKx1A7EkU3todYwaK64w/0D+Vy8UzTwGkNg88SB+s62nHJyT1fC8arT5mL+lsaIFPZlDOQFSEc3xZwikOM=",
        # "-Dapp.authorization.keys.1.x5t=GVjYJwEC-mu2706DzWYSRddCshg",
        # "-Dapp.authorization.keys.1.x5t#S256=y5o4V73ANlLdVlrf5h-FQ3gVeMjlQuuocce2zSMqg7Y"
      ]
      networkMode = "awsvpc"
      family      = "sbostorageapp" # TODO might be defined elsewhere?
      essential   = true
      image       = var.nexus_storage_docker_image_url
      name        = "nexus_storage"
      repositoryCredentials = {
        credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8081
          containerPort = 8081
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO is this needed? Status check is done on version endpoint?
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.nexus_storage_service_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_storage"
        }
      }
    }
  ])

  cpu                      = 2048
  memory                   = 8192
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_nexus_storage_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_nexus_storage_task_role[0].arn

  tags = {
    SBO_Billing = "nexus_storage"
  }
}

resource "aws_ecs_service" "nexus_storage_ecs_service" {
  count = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0

  name            = "nexus_storage_ecs_service"
  cluster         = aws_ecs_cluster.nexus_storage.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.nexus_storage_ecs_definition[0].arn
  desired_count   = var.nexus_storage_ecs_number_of_containers

  # TODO add a load balancer once the container is running (though it may not be needed)
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.nexus_storage.arn
  #   container_name   = "nexus_storage"
  #   container_port   = 8081
  # }

  network_configuration {
    security_groups = [aws_security_group.nexus_storage_ecs_task.id]
    # TODO using the same subnet as Nexus Delta, may be ok?
    subnets          = [aws_subnet.nexus_app.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_storage,
    aws_iam_role.ecs_nexus_storage_task_execution_role,
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus_storage"
  }
}

resource "aws_iam_role" "ecs_nexus_storage_task_execution_role" {
  count = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_storage-ecsTaskExecutionRole"

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
    SBO_Billing = "nexus_storage"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_storage_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_nexus_storage_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0
}

# TODO the only thing different with this role is the name?
resource "aws_iam_role" "ecs_nexus_storage_task_role" {
  count = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_storage-ecsTaskRole"

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
    SBO_Billing = "nexus_storage"
  }
}

# TODO we also need a roles / policies for reading and writing to S3
resource "aws_iam_role_policy_attachment" "ecs_nexus_storage_task_role_dockerhub_policy_attachment" {
  count      = var.nexus_storage_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_storage_task_execution_role[0].name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}
