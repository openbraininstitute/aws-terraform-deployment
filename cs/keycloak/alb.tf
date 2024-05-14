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

resource "aws_lb_listener_rule" "keycloak_https" {
  listener_arn = var.public_alb_listener 
  priority     = 555
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak_target_group.arn
  }
  condition {
    host_header {
      values = [var.primary_auth_hostname, var.secondary_auth_hostname]
    }
  }
  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
  condition {
    source_ip {
      values = [var.epfl_cidr, var.bbpproxy_cidr]
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}
