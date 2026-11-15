# Least privilege by security-group reference: only the private ALB and
# the page router reach the tasks, only the ALB reaches the router, and
# only the tasks (plus the bastion, for psql
# maintenance such as creating the logbook_jobs role) reach Postgres
# and Redis. Tighter than the VPC-wide rules of older modules, at no
# extra cost.

resource "aws_security_group" "logbook_ecs_task" {
  name_prefix = "logbook"
  vpc_id      = var.vpc_id
  description = "Sec group for the logbook server tasks"

  tags = {
    Name = "logbook_secgroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "logbook_from_alb" {
  security_group_id = aws_security_group.logbook_ecs_task.id

  ip_protocol                  = "tcp"
  from_port                    = local.container_port
  to_port                      = local.container_port
  referenced_security_group_id = var.private_alb_security_group_id
  description                  = "HTTP and WebSocket from the private ALB (traffic and health checks)"
}

resource "aws_vpc_security_group_egress_rule" "logbook_allow_outgoing" {
  security_group_id = aws_security_group.logbook_ecs_task.id
  # Postgres, Redis, ECR, Keycloak and EntityCore (through the ALB); same as the other services.
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all outgoing"
}

resource "aws_vpc_security_group_ingress_rule" "logbook_from_router" {
  security_group_id = aws_security_group.logbook_ecs_task.id

  ip_protocol                  = "tcp"
  from_port                    = local.container_port
  to_port                      = local.container_port
  referenced_security_group_id = aws_security_group.logbook_router.id
  description                  = "HTTP and WebSocket of the pages from the page router (traffic and its /readyz checks)"
}

# The page router (router.tf): reached only by the private ALB, and
# reaches only the server tasks (plus ECR and CloudWatch Logs at start).
resource "aws_security_group" "logbook_router" {
  name_prefix = "logbook_router"
  vpc_id      = var.vpc_id
  description = "Sec group for the logbook page router tasks"

  tags = {
    Name = "logbook_router_secgroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "logbook_router_from_alb" {
  security_group_id = aws_security_group.logbook_router.id

  ip_protocol                  = "tcp"
  from_port                    = local.router_port
  to_port                      = local.router_port
  referenced_security_group_id = var.private_alb_security_group_id
  description                  = "HTTP and WebSocket from the private ALB (page traffic and health checks)"
}

resource "aws_vpc_security_group_egress_rule" "logbook_router_allow_outgoing" {
  security_group_id = aws_security_group.logbook_router.id
  # The tasks, the VPC DNS resolver (Cloud Map), ECR and CloudWatch Logs; same as the tasks.
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all outgoing"
}

resource "aws_security_group" "logbook_db" {
  name_prefix = "logbook_db"
  vpc_id      = var.vpc_id
  description = "Logbook PostgreSQL"

  tags = {
    Name = "logbook_db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "logbook_db_from_tasks" {
  security_group_id = aws_security_group.logbook_db.id

  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.logbook_ecs_task.id
  description                  = "Postgres from the logbook tasks"
}

resource "aws_vpc_security_group_ingress_rule" "logbook_db_from_bastion" {
  security_group_id = aws_security_group.logbook_db.id

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
  cidr_ipv4   = var.bastion_cidr_block
  description = "Postgres from the bastion host, for maintenance"
}

resource "aws_security_group" "logbook_redis" {
  name_prefix = "logbook_redis"
  vpc_id      = var.vpc_id
  description = "Logbook Redis"

  tags = {
    Name = "logbook_redis"
  }
}

resource "aws_vpc_security_group_ingress_rule" "logbook_redis_from_tasks" {
  security_group_id = aws_security_group.logbook_redis.id

  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.logbook_ecs_task.id
  description                  = "Redis from the logbook tasks"
}
