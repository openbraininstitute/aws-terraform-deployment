resource "aws_lb" "nexus_rds" {
  name               = "nexus-rds-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.subnet_security_group_id]
  subnets            = var.subnets_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "nexus_rds" {
  name        = "nexus-rds-tg"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "TCP"
    port                = 5432 # Same as target group port
  }
}

resource "aws_lb_target_group_attachment" "primary_rds" {
  target_group_arn = aws_lb_target_group.nexus_rds.arn
  target_id        = aws_db_instance.nexusdb.address
  port             = 5432
}

resource "aws_lb_target_group_attachment" "replica_rds" {
  target_group_arn = aws_lb_target_group.nexus_rds.arn
  target_id        = aws_db_instance.nexusdb_read_replica.address
  port             = 5432
}

resource "aws_lb_listener" "rds_listener" {
  load_balancer_arn = aws_lb.nexus_rds.arn
  port              = 5432
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus_rds.arn
  }
}