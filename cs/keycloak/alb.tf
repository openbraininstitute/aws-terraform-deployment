resource "aws_lb" "keycloak_lb" {
  name               = "keycloak-lb"
  internal           = false #tfsec:ignore:aws-elb-alb-not-public
  load_balancer_type = "application"
  subnets            = var.alb_subnets
  security_groups    = var.security_groups
  drop_invalid_header_fields = true

  tags = {
    Name = "Keycloak Load Balancer"
  }
}

resource "aws_lb_listener" "keycloak" {
  load_balancer_arn = aws_lb.keycloak_lb.arn
  port              = 80
  #ts:skip=AC_AWS_0491
  protocol          = "HTTP" #tfsec:ignore:aws-elb-http-not-used

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak_target_group.arn
  }
}

#  Configure ALB target group
resource "aws_lb_target_group" "keycloak_target_group" {
  name        = "keycloak-target-group"
  port        = 8081
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id =  var.vpc_id
  tags = {
    Name = "Keycloak Target Group"
  }
  health_check {
    path                = "/auth/health"  
    port                = "8081"          
    protocol            = "HTTPS"         
    interval            = 30              
    timeout             = 5               
    healthy_threshold   = 2               
    unhealthy_threshold = 2               
    matcher             = "200-399" 
  }
}

resource "aws_lb_listener_rule" "auth_path_rule" {
  listener_arn = aws_lb_listener.keycloak.arn  
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak_target_group.arn  
  }

  condition {
    path_pattern {
      values = ["/auth"]
    }
  }
}
